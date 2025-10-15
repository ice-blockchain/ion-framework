// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/providers/dio_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/file_storage_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_auth.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user/providers/relays/ranked_user_relays_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relays_replica_delay_provider.m.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';

Future<String> generateAuthorizationToken({
  required Ref ref,
  required String url,
  required String method,
  List<int>? fileBytes,
  EventSigner? customEventSigner,
}) async {
  // Resolve signer pubkey (device) and master pubkey for logging
  final resolvedSigner =
      customEventSigner ?? await ref.read(currentUserIonConnectEventSignerProvider.future);
  final devicePubkey = resolvedSigner?.publicKey;
  final masterPubkey = ref.read(currentPubkeySelectorProvider);

  // NOSTR.NIP98 build_start
  Logger.info(
      'NOSTR.NIP98 build_start nip98.pubkey=${devicePubkey ?? 'null'} nip98.master=${masterPubkey ?? 'null'} nip98.u=$url nip98.method=$method');

  // Attach 10100 attestation inline when replica delay is active
  final isDelayed = ref.read(relaysReplicaDelayProvider).isDelayed;
  final userDelegation =
      isDelayed ? await ref.read(currentUserCachedDelegationProvider.future) : null;

  final ionConnectAuth = IonConnectAuth(
    url: url,
    method: method,
    payload: fileBytes,
    userDelegation: userDelegation,
  );

  if (customEventSigner != null) {
    final authEvent = await ionConnectAuth.toEventMessage(customEventSigner);

    // NOSTR.NIP98 sign_ok
    Logger.info('NOSTR.NIP98 sign_ok nip98.pubkey=${customEventSigner.publicKey}');
    return ionConnectAuth.toAuthorizationHeader(authEvent);
  } else {
    final authEvent = await ref.read(ionConnectNotifierProvider.notifier).sign(ionConnectAuth);
    // NOSTR.NIP98 sign_ok
    Logger.info('NOSTR.NIP98 sign_ok nip98.pubkey=${devicePubkey ?? 'null'}');
    return ionConnectAuth.toAuthorizationHeader(authEvent);
  }
}

// TODO: handle delegatedToUrl when migrating to common relays
Future<String> getFileStorageApiUrl(
  Ref ref, {
  CancelToken? cancelToken,
}) async {
  final userRelays = await ref.read(rankedCurrentUserRelaysProvider.future);
  if (userRelays.isEmpty) {
    throw UserRelaysNotFoundException();
  }
  final relayUrl = userRelays.first.url;

  try {
    final parsedRelayUrl = Uri.parse(relayUrl);
    final metadataUri = Uri(
      scheme: 'https',
      host: parsedRelayUrl.host,
      port: parsedRelayUrl.hasPort ? parsedRelayUrl.port : null,
      path: FileStorageMetadata.path,
    );

    // NOSTR.NIP96 get_start
    final discoveryHost = metadataUri.authority;
    Logger.info('NOSTR.NIP96 get_start host=$discoveryHost');

    final response = await ref.read(dioProvider).getUri<dynamic>(
          metadataUri,
          cancelToken: cancelToken,
        );
    final jsonMap = json.decode(response.data as String) as Map<String, dynamic>;
    final metadata = FileStorageMetadata.fromJson(jsonMap);
    final path = metadata.apiUrl;
    final uploadUrl = metadataUri.replace(path: path).toString();

    // Parse is_nip98_required from top-level of or plans from jsonMap (For log purposes)
    final isNip98Required =
        (jsonMap['is_nip98_required'] as bool?) ?? _extractIsNip98FromPlans(jsonMap['plans']);

    // NOSTR.NIP96 get_ok
    Logger.info(
        'NOSTR.NIP96 get_ok host=$discoveryHost upload_url=$uploadUrl is_nip98_required=$isNip98Required');

    return uploadUrl;
  } catch (error) {
    if (_isRelayDead(error)) {
      ref.read(rankedCurrentUserRelaysProvider.notifier).reportUnreachableRelay(relayUrl);
      return getFileStorageApiUrl(
        ref,
        cancelToken: cancelToken,
      );
    }
    throw GetFileStorageUrlException(error);
  }
}

bool _isRelayDead(Object error) {
  // To be adjusted
  return true;
}

/// Extracts is_nip98_required from plans in jsonMap (For log purposes only)
/// We need this when is_nip98_required is not present at the top-level of the jsonMap
bool _extractIsNip98FromPlans(dynamic plansJson) {
  if (plansJson is Map<String, dynamic>) {
    for (final entry in plansJson.values) {
      if (entry is Map<String, dynamic>) {
        final value = entry['is_nip98_required'];
        if (value is bool && value) {
          return true;
        }
      }
    }
  }
  return false;
}

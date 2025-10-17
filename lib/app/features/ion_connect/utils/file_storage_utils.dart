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
import 'package:ion/app/features/ion_connect/providers/relays/relays_replica_delay_provider.m.dart';
import 'package:ion/app/features/user/providers/relays/ranked_user_relays_provider.r.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';

Future<String> generateAuthorizationToken({
  required Ref ref,
  required String url,
  required String method,
  List<int>? fileBytes,
  EventSigner? customEventSigner,
}) async {
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

    return ionConnectAuth.toAuthorizationHeader(authEvent);
  } else {
    final authEvent = await ref.read(ionConnectNotifierProvider.notifier).sign(ionConnectAuth);

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

    final response = await ref.read(dioProvider).getUri<dynamic>(
          metadataUri,
          cancelToken: cancelToken,
        );
    final jsonMap = json.decode(response.data as String) as Map<String, dynamic>;
    final metadata = FileStorageMetadata.fromJson(jsonMap);
    final path = metadata.apiUrl;
    final uploadUrl = metadataUri.replace(path: path).toString();

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

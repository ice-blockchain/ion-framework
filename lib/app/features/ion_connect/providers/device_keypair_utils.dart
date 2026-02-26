// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/dio_provider.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_constants.dart';
import 'package:ion/app/features/ion_connect/utils/file_storage_utils.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/current_user_identity_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/ranked_user_relays_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart';

/// Utility class for shared device keypair operations
class DeviceKeypairUtils {
  /// Finds or creates a device key for synchronization operations
  static Future<KeyResponse?> findDeviceKey({
    required Ref ref,
  }) async {
    final ionIdentity = await ref.read(ionIdentityClientProvider.future);
    final keysResponse = await ionIdentity.keys.listKeys();

    return keysResponse.items.firstWhereOrNull((key) => key.name == DeviceKeypairConstants.keyName);
  }

  static Future<KeyResponse> findOrCreateDeviceKey({
    required Ref ref,
    required UserActionSignerNew signer,
  }) async {
    final existingKey = await findDeviceKey(ref: ref);
    if (existingKey != null) {
      return existingKey;
    }

    final ionIdentity = await ref.read(ionIdentityClientProvider.future);
    return ionIdentity.keys.createKey(
      scheme: DeviceKeypairConstants.scheme,
      curve: DeviceKeypairConstants.curve,
      name: DeviceKeypairConstants.keyName,
      signer: signer,
    );
  }

  /// Finds the device keypair MediaAttachment from current user's metadata
  static MediaAttachment? extractDeviceKeypairAttachmentFromMetadata(UserMetadataEntity? metadata) {
    if (metadata == null) {
      return null;
    }

    // Find device keypair attachment by alt field
    return metadata.data.media.values
        .where((attachment) => attachment.alt == FileAlt.attestationKey.toShortString())
        .firstOrNull;
  }

  static Future<MediaAttachment?> findDeviceKeypairAttachment({
    required Ref ref,
  }) async {
    try {
      final currentUserMetadata = await ref.read(currentUserMetadataProvider.future);
      return extractDeviceKeypairAttachmentFromMetadata(currentUserMetadata);
    } catch (e) {
      return null;
    }
  }

  /// Generates derivation for device keypair encryption/decryption
  static Future<DeriveResponse> generateDerivation({
    required Ref ref,
    required String keyId,
    required UserActionSignerNew signer,
  }) async {
    final domain = hex.encode(DeviceKeypairConstants.domain.codeUnits);
    final seed = await generateSeed(ref);

    final ionIdentity = await ref.read(ionIdentityClientProvider.future);
    return ionIdentity.keys.derive(
      keyId: keyId,
      domain: domain,
      seed: seed,
      signer: signer,
    );
  }

  static Future<String> generateSeed(Ref ref) async {
    final userDetails = await ref.read(currentUserIdentityProvider.future);
    if (userDetails?.userId == null) {
      throw DeviceKeypairRestoreException('User ID not found');
    }
    const keyName = DeviceKeypairConstants.keyName;
    final userId = userDetails!.userId;
    final checksum = ref.read(envProvider.notifier).get<String>(EnvVariable.CHECKSUM);

    return hex.encode('$keyName:$userId:$checksum'.codeUnits);
  }

  /// Decrypts device keypair using AES-GCM
  static Future<String> decryptDeviceKeypair(
    Uint8List encryptedData,
    String derivationOutput,
  ) async {
    final dataString = utf8.decode(encryptedData);
    final data = jsonDecode(dataString) as Map<String, dynamic>;

    final nonce = base64Decode(data['nonce'] as String);
    final ciphertext = base64Decode(data['ciphertext'] as String);
    final macBytes = base64Decode(data['mac'] as String);

    final raw =
        derivationOutput.startsWith('0x') ? derivationOutput.substring(2) : derivationOutput;
    final keyBytes = hex.decode(raw);
    final secretKey = SecretKey(keyBytes.take(32).toList());

    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox(ciphertext, nonce: nonce, mac: Mac(macBytes));

    final decryptedData = await algorithm.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(decryptedData);
  }

  /// Downloads encrypted keypair from relays using proper file storage URL discovery
  static Future<Uint8List> downloadEncryptedKeypair(String fileId, Ref ref) async {
    final relayUrls = await _resolveDeviceKeypairRelayUrls(ref);
    if (relayUrls.isEmpty) {
      throw DeviceKeypairRestoreException(
        'Failed to restore device keypair: no available ranked relays',
      );
    }

    final dio = ref.read(dioProvider);
    final errors = <String>[];

    for (final relayUrl in relayUrls) {
      try {
        final baseStorageUrl = await resolveFileStorageApiUrlFromRelayUrl(
          ref,
          relayUrl: relayUrl,
        );
        final downloadUrl = _buildDownloadUrl(baseStorageUrl: baseStorageUrl, fileId: fileId);

        final response = await dio.get<List<int>>(
          downloadUrl,
          options: Options(responseType: ResponseType.bytes),
        );

        if (response.statusCode == 200 && response.data != null) {
          return Uint8List.fromList(response.data!);
        }

        errors.add('$relayUrl: HTTP ${response.statusCode}');
      } catch (error, stackTrace) {
        Logger.error(
          error,
          stackTrace: stackTrace,
          message: 'Failed to restore device keypair from relay $relayUrl',
        );
        errors.add('$relayUrl: $error');
      }
    }

    throw DeviceKeypairRestoreException(
      'Failed to download encrypted keypair from ${relayUrls.length} relay candidate(s): ${errors.join(' | ')}',
    );
  }

  static Future<List<String>> _resolveDeviceKeypairRelayUrls(Ref ref) async {
    try {
      final userRelays = await ref.read(rankedCurrentUserRelaysProvider.future);
      return userRelays.map((relay) => relay.url).toList();
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to load ranked relay URLs for device keypair restore',
      );
      return [];
    }
  }

  static String _buildDownloadUrl({
    required String baseStorageUrl,
    required String fileId,
  }) {
    final normalized = baseStorageUrl.endsWith('/')
        ? baseStorageUrl.substring(0, baseStorageUrl.length - 1)
        : baseStorageUrl;
    return '$normalized/$fileId';
  }

  /// Extracts file ID from URL
  static String? extractFileIdFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    final uri = Uri.tryParse(url);
    if (uri?.pathSegments.isNotEmpty ?? false) {
      return uri!.pathSegments.last;
    }

    return null;
  }
}

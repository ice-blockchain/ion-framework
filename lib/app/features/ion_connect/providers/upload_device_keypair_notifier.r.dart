// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/model/file_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_dialog_manager.r.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_utils.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
import 'package:ion/app/features/user/providers/update_user_metadata_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upload_device_keypair_notifier.r.g.dart';

@riverpod
class UploadDeviceKeypairNotifier extends _$UploadDeviceKeypairNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> uploadDeviceKeypair({
    required UserActionSignerNew signer,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final deviceKeypair = await _getDeviceKeypair();
        final deviceKey = await DeviceKeypairUtils.findOrCreateDeviceKey(
          ref: ref,
          signer: signer,
        );
        final derivation = await DeviceKeypairUtils.generateDerivation(
          ref: ref,
          keyId: deviceKey.id,
          signer: signer,
        );

        final encryptedKeypair = await _encryptDeviceKeypair(
          deviceKeypair.privateKey,
          derivation.output,
        );

        final uploadResult = await _uploadEncryptedKeypair(encryptedKeypair);
        await ref
            .read(ionConnectNotifierProvider.notifier)
            .sendEntityData(uploadResult.fileMetadata);

        // Add device keypair MediaAttachment to current user's metadata
        await _addDeviceKeypairToUserMetadata(uploadResult.mediaAttachment);

        // Mark as completed and uploaded from this device
        final dialogManager = ref.read(deviceKeypairDialogManagerProvider.notifier);
        await dialogManager.markCompleted();
        await dialogManager.markUploadedFromThisDevice();
      } catch (error) {
        throw DeviceKeypairUploadException(error);
      }
    });
  }

  Future<EventSigner> _getDeviceKeypair() async {
    final deviceKeypair = await ref.read(currentUserIonConnectEventSignerProvider.future);
    if (deviceKeypair == null) {
      throw DeviceKeypairUploadException('Device keypair not found');
    }
    return deviceKeypair;
  }

  /// Adds the device keypair MediaAttachment to the current user's metadata
  Future<void> _addDeviceKeypairToUserMetadata(MediaAttachment mediaAttachment) async {
    try {
      final currentUserMetadata = await ref.read(currentUserMetadataProvider.future);
      if (currentUserMetadata == null) {
        throw DeviceKeypairUploadException('Current user metadata not found');
      }

      // Add the device keypair attachment to the media map
      final updatedMetadata = currentUserMetadata.data.copyWith(
        media: {
          ...currentUserMetadata.data.media,
          mediaAttachment.url: mediaAttachment,
        },
      );

      // Update user metadata
      await ref.read(updateUserMetadataNotifierProvider.notifier).publish(updatedMetadata);
    } catch (e) {
      Logger.error(e, message: 'Failed to add device keypair to user metadata');
      throw DeviceKeypairUploadException('Failed to add device keypair to user metadata');
    }
  }

  /// Encrypts the device keypair using AES-GCM with the derivation output as the key
  Future<Uint8List> _encryptDeviceKeypair(String privateKey, String derivationOutput) async {
    final raw =
        derivationOutput.startsWith('0x') ? derivationOutput.substring(2) : derivationOutput;
    final keyBytes = hex.decode(raw);
    final secretKey = SecretKey(keyBytes.take(32).toList());

    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(utf8.encode(privateKey), secretKey: secretKey);

    final encryptedData = {
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };

    return Uint8List.fromList(utf8.encode(jsonEncode(encryptedData)));
  }

  /// Uploads the encrypted keypair to relays using the existing NIP-94 infrastructure
  Future<({FileMetadata fileMetadata, MediaAttachment mediaAttachment})> _uploadEncryptedKeypair(
    Uint8List encryptedData,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/device_keypair');
    await tempFile.writeAsBytes(encryptedData);

    final mediaFile = MediaFile(
      path: tempFile.path,
      mimeType: MimeType.generic.value,
    );

    try {
      return await ref.read(ionConnectUploadNotifierProvider.notifier).upload(
            mediaFile,
            alt: FileAlt.attestationKey.toShortString(),
            skipDimCheck: true,
          );
    } finally {
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
    }
  }
}

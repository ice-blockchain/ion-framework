// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_dialog_manager.r.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_utils.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'restore_device_keypair_notifier.r.g.dart';

@riverpod
class RestoreDeviceKeypairNotifier extends _$RestoreDeviceKeypairNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> restoreDeviceKeypair({
    required UserActionSignerNew signer,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      try {
        final currentIdentityKeyName = _getCurrentIdentityKeyName();
        final deviceKeypairAttachment =
            await DeviceKeypairUtils.findDeviceKeypairAttachment(ref: ref);

        if (deviceKeypairAttachment == null) {
          throw DeviceKeypairRestoreException('No device keypair backup found in user metadata');
        }

        final fileId = DeviceKeypairUtils.extractFileIdFromUrl(deviceKeypairAttachment.url);

        if (fileId == null) {
          throw DeviceKeypairRestoreException('Could not extract file ID from device keypair URL');
        }

        final encryptedData = await DeviceKeypairUtils.downloadEncryptedKeypair(fileId, ref);

        final deviceKey = await DeviceKeypairUtils.findOrCreateDeviceKey(
          ref: ref,
          signer: signer,
        );
        final derivation = await DeviceKeypairUtils.generateDerivation(
          ref: ref,
          keyId: deviceKey.id,
          signer: signer,
        );

        final decryptedPrivateKey = await DeviceKeypairUtils.decryptDeviceKeypair(
          encryptedData,
          derivation.output,
        );

        await _restoreKeypairToDevice(decryptedPrivateKey, currentIdentityKeyName);

        // Mark as completed
        final dialogManager = ref.read(deviceKeypairDialogManagerProvider.notifier);
        await dialogManager.markCompleted();
      } catch (error) {
        throw DeviceKeypairRestoreException(error);
      }
    });
  }

  Future<List<String>> listAvailableDeviceKeys() async {
    final deviceKeypairAttachment = await DeviceKeypairUtils.findDeviceKeypairAttachment(ref: ref);
    if (deviceKeypairAttachment != null) {
      return [deviceKeypairAttachment.url];
    }
    return [];
  }

  String _getCurrentIdentityKeyName() {
    final currentIdentityKeyName = ref.read(currentIdentityKeyNameSelectorProvider);
    if (currentIdentityKeyName == null) {
      throw const CurrentUserNotFoundException();
    }
    return currentIdentityKeyName;
  }

  /// Restores the decrypted keypair to the device storage and returns the event signer
  Future<EventSigner> _restoreKeypairToDevice(
    String privateKey,
    String identityKeyName,
  ) async {
    // Restore the keypair using the ion connect event signer provider
    final eventSignerNotifier =
        ref.read(ed25519IonConnectEventSignerProviderProvider(identityKeyName).notifier);

    // Use the restoreFromPrivateKey method to restore the keypair
    return eventSignerNotifier.restoreFromPrivateKey(privateKey);
  }
}

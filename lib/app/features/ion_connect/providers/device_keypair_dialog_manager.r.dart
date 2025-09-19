// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_dialog_state.f.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_utils.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_keypair_dialog_manager.r.g.dart';

@riverpod
class DeviceKeypairDialogManager extends _$DeviceKeypairDialogManager {
  static const String _completedKeyPrefix = 'device_keypair_completed';
  static const String _uploadedFromDeviceKeyPrefix = 'device_keypair_uploaded_from_device';

  @override
  DeviceKeypairSessionState build() {
    return const DeviceKeypairSessionState();
  }

  /// Determines the current state of device keypair synchronization
  Future<DeviceKeypairState> getCurrentState() async {
    try {
      // Respect suppression flag: if user opted out, never show again
      final isSuppressed = await ref.read(deviceKeypairDialogSuppressedProvider.future);
      if (isSuppressed) {
        return DeviceKeypairState.rejectedThisSession;
      }

      // Check if user completed upload/restore on this device
      final hasCompleted = await _hasCompletedOnThisDevice();
      if (hasCompleted) {
        return DeviceKeypairState.completed;
      }

      // Check session rejections
      if (state.rejected) {
        return DeviceKeypairState.rejectedThisSession;
      }

      // Check if user uploaded from this device (don't ask to restore)
      final uploadedFromThisDevice = await _hasUploadedFromThisDevice();
      if (uploadedFromThisDevice) {
        return DeviceKeypairState.completed;
      }

      // Check if there's a device keypair backup in user metadata
      final hasDeviceKeypairBackup =
          (await DeviceKeypairUtils.findDeviceKeypairAttachment(ref: ref)) != null;

      // If device keypair backup exists in user metadata, user should restore
      if (hasDeviceKeypairBackup) {
        return DeviceKeypairState.needsRestore;
      }

      // Check if device key exists (upload was started)
      final deviceKey = await DeviceKeypairUtils.findDeviceKey(ref: ref);

      // If device key exists but no backup in metadata, upload was interrupted
      if (deviceKey != null) {
        return DeviceKeypairState.uploadInProgress;
      }

      // If no device key and no backup, need to start upload
      return DeviceKeypairState.needsUpload;
    } catch (e) {
      // If any error occurs, assume we need to start upload
      return DeviceKeypairState.needsUpload;
    }
  }

  /// Marks that the user rejected the action
  void reject() {
    state = state.copyWith(rejected: true);
  }

  /// Marks that the user completed upload/restore on this device
  Future<void> markCompleted() async {
    final localStorage = ref.read(localStorageProvider);
    await localStorage.setBool(key: _getCompletedKey(), value: true);
  }

  /// Marks that the user uploaded from this device
  Future<void> markUploadedFromThisDevice() async {
    final localStorage = ref.read(localStorageProvider);
    await localStorage.setBool(key: _getUploadedFromDeviceKey(), value: true);
  }

  /// Resets all persistent state (for testing/debugging)
  Future<void> resetState() async {
    final localStorage = ref.read(localStorageProvider);
    await localStorage.remove(_getCompletedKey());
    await localStorage.remove(_getUploadedFromDeviceKey());
    await ref.read(deviceKeypairDialogShownOnceProvider.notifier).reset();
    await ref.read(deviceKeypairDialogSuppressedProvider.notifier).reset();
    state = const DeviceKeypairSessionState();
  }

  /// Checks if user has completed upload/restore on this device
  Future<bool> _hasCompletedOnThisDevice() async {
    try {
      final localStorage = ref.read(localStorageProvider);
      return localStorage.getBool(_getCompletedKey()) ?? false;
    } catch (e) {
      Logger.log('Error checking completion status', error: e);
      return false;
    }
  }

  /// Checks if user uploaded from this device
  Future<bool> _hasUploadedFromThisDevice() async {
    try {
      final localStorage = ref.read(localStorageProvider);
      return localStorage.getBool(_getUploadedFromDeviceKey()) ?? false;
    } catch (e) {
      Logger.log('Error checking upload status', error: e);
      return false;
    }
  }

  /// Gets user-specific storage key for completion status
  String _getCompletedKey() {
    final identityKeyName = ref.read(currentIdentityKeyNameSelectorProvider);
    if (identityKeyName == null) {
      throw const CurrentUserNotFoundException();
    }
    return '${_completedKeyPrefix}_$identityKeyName';
  }

  /// Gets user-specific storage key for upload-from-device status
  String _getUploadedFromDeviceKey() {
    final identityKeyName = ref.read(currentIdentityKeyNameSelectorProvider);
    if (identityKeyName == null) {
      throw const CurrentUserNotFoundException();
    }
    return '${_uploadedFromDeviceKeyPrefix}_$identityKeyName';
  }
}

@riverpod
class DeviceKeypairDialogSuppressed extends _$DeviceKeypairDialogSuppressed {
  static const _storageKeyPrefix = 'device_keypair_dialog_suppressed';

  String _makeKey() => _storageKeyPrefix;

  @override
  Future<bool> build() async {
    final prefs = ref.watch(currentUserPreferencesServiceProvider);
    if (prefs == null) return false;
    return prefs.getValue<bool>(_makeKey()) ?? false;
  }

  Future<void> setSuppressed({required bool value}) async {
    final prefs = ref.read(currentUserPreferencesServiceProvider);
    if (prefs == null) return;
    await prefs.setValue(_makeKey(), value);
    state = AsyncData(value);
  }

  Future<void> reset() async => setSuppressed(value: false);
}

@riverpod
class DeviceKeypairDialogShownOnce extends _$DeviceKeypairDialogShownOnce {
  static const _storageKeyPrefix = 'device_keypair_dialog_shown_once';

  String _makeKey() => _storageKeyPrefix;

  @override
  Future<bool> build() async {
    final prefs = ref.watch(currentUserPreferencesServiceProvider);
    if (prefs == null) return false;
    return prefs.getValue<bool>(_makeKey()) ?? false;
  }

  Future<void> markShownOnce() async => _setShownOnce(value: true);

  Future<void> reset() async => _setShownOnce(value: false);

  Future<void> _setShownOnce({required bool value}) async {
    final prefs = ref.read(currentUserPreferencesServiceProvider);
    if (prefs == null) return;
    await prefs.setValue(_makeKey(), value);
    state = AsyncData(value);
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recovery_keys_completed_provider.r.g.dart';

@riverpod
class RecoveryKeysCompleted extends _$RecoveryKeysCompleted {
  static const String _completedKeyPrefix = 'recovery_keys_completed';

  @override
  Future<bool> build() async {
    final currentIdentityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
    if (currentIdentityKeyName == null) {
      return false;
    }

    final localStorage = ref.watch(localStorageProvider);
    final key = _getRecoveryKeysCompletedKey(currentIdentityKeyName);
    return localStorage.getBool(key) ?? false;
  }

  Future<void> markCompleted() async {
    final currentIdentityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
    if (currentIdentityKeyName == null) {
      return;
    }

    final localStorage = ref.watch(localStorageProvider);
    final key = _getRecoveryKeysCompletedKey(currentIdentityKeyName);
    await localStorage.setBool(key: key, value: true);

    // Invalidate the provider to update the state
    ref.invalidateSelf();
  }

  String _getRecoveryKeysCompletedKey(String identityKeyName) {
    return '${_completedKeyPrefix}_$identityKeyName';
  }
}

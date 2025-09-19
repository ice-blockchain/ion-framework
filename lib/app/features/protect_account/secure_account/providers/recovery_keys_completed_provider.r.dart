// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recovery_keys_completed_provider.r.g.dart';

@riverpod
class RecoveryKeysCompleted extends _$RecoveryKeysCompleted {
  static const String _completedKey = 'recovery_keys_completed';

  @override
  Future<bool> build() async {
    final currentIdentityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
    if (currentIdentityKeyName == null) {
      return false;
    }

    final userPreferencesService = ref.watch(
      userPreferencesServiceProvider(identityKeyName: currentIdentityKeyName),
    );
    return userPreferencesService.getValue<bool>(_completedKey) ?? false;
  }

  Future<void> markCompleted() async {
    final currentIdentityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
    if (currentIdentityKeyName == null) {
      return;
    }

    final userPreferencesService = ref.read(
      userPreferencesServiceProvider(identityKeyName: currentIdentityKeyName),
    );
    await userPreferencesService.setValue(_completedKey, true);

    // Invalidate the provider to update the state
    ref.invalidateSelf();
  }
}

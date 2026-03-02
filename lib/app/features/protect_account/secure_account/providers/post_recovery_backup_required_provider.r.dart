// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_recovery_backup_required_provider.r.g.dart';

@riverpod
class PostRecoveryBackupRequired extends _$PostRecoveryBackupRequired {
  static const String _storageKey = 'post_recovery_backup_required';

  @override
  bool build() {
    final userPreferencesService = ref.watch(currentUserPreferencesServiceProvider);
    return userPreferencesService?.getValue<bool>(_storageKey) ?? false;
  }

  Future<void> markRequiredForIdentity(String identityKeyName) async {
    final userPreferencesService =
        ref.read(userPreferencesServiceProvider(identityKeyName: identityKeyName));
    await userPreferencesService.setValue<bool>(_storageKey, true);
  }

  Future<void> clear() async {
    final userPreferencesService = ref.read(currentUserPreferencesServiceProvider);
    if (userPreferencesService == null) {
      return;
    }

    await userPreferencesService.remove(_storageKey);
    state = false;
  }
}

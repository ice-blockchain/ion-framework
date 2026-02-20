// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'synced_fcm_token_provider.r.g.dart';

@riverpod
class SyncedFcmToken extends _$SyncedFcmToken {
  static const _syncedFcmTokenKey = 'synced_fcm_token_v1';

  @override
  String? build() {
    final prefs = ref.watch(currentUserPreferencesServiceProvider);
    return prefs?.getValue<String>(_syncedFcmTokenKey);
  }

  Future<void> setToken(String value) async {
    final prefs = ref.read(currentUserPreferencesServiceProvider);
    await prefs?.setValue<String>(_syncedFcmTokenKey, value);
    state = value;
  }
}

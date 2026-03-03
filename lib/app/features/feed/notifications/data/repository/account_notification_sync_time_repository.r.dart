// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_notification_sync_time_repository.r.g.dart';

@Riverpod(keepAlive: true)
AccountNotificationSyncTimeRepository? accountNotificationSyncTimeRepository(Ref ref) {
  final prefs = ref.watch(currentUserPreferencesServiceProvider);
  if (prefs == null) {
    return null;
  }

  return AccountNotificationSyncTimeRepository(userPreferencesService: prefs);
}

class AccountNotificationSyncTimeRepository {
  AccountNotificationSyncTimeRepository({
    required UserPreferencesService userPreferencesService,
  }) : _userPreferencesService = userPreferencesService;

  final UserPreferencesService _userPreferencesService;

  static const _lastSyncTimeKey = 'account_notification_last_sync_time_v1';

  DateTime? getLastSyncTime() {
    final timestamp = _userPreferencesService.getValue<int>(_lastSyncTimeKey);
    if (timestamp == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> setLastSyncTime(DateTime value) {
    return _userPreferencesService.setValue<int>(_lastSyncTimeKey, value.millisecondsSinceEpoch);
  }
}

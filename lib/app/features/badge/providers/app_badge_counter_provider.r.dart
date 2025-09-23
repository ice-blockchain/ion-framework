// SPDX-License-Identifier: ice License 1.0

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_badge_counter_provider.r.g.dart';

enum CounterCategory {
  inapp('app_badge_count'),
  chat('app_badge_chat_count');

  const CounterCategory(this.key);

  final String key;
}

class AppBadgeCounter {
  AppBadgeCounter(this.sharedPreferencesFoundation);

  final SharedPreferencesAsync sharedPreferencesFoundation;

  Future<void> setBadgeCount(int count, CounterCategory category) async {
    if (await AppBadgePlus.isSupported()) {
      await Future.wait([
        sharedPreferencesFoundation.setInt(category.key, count),
        AppBadgePlus.updateBadge(
          await _updateBadgeCount(),
        ),
      ]);
    }
  }

  Future<void> clearBadge(CounterCategory category) async => setBadgeCount(0, category);

  Future<void> clearUnreadConversations() async =>
      sharedPreferencesFoundation.remove('unread_conversations');

  Future<void> clearAllBadges() async {
    if (await AppBadgePlus.isSupported()) {
      final clearOperations = CounterCategory.values
          .map((category) => sharedPreferencesFoundation.setInt(category.key, 0));

      await Future.wait([
        ...clearOperations,
        AppBadgePlus.updateBadge(0),
      ]);
    }
  }

  Future<int> _updateBadgeCount() async {
    final countFutures =
        CounterCategory.values.map((category) => sharedPreferencesFoundation.getInt(category.key));

    final counts = await Future.wait(countFutures);

    return counts.fold<int>(0, (sum, count) => sum + (count ?? 0));
  }
}

@riverpod
Future<AppBadgeCounter?> appBadgeCounter(Ref ref) async {
  keepAliveWhenAuthenticated(ref);

  final identityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
  if (identityKeyName == null) {
    return null;
  }

  final sharedPreferencesFoundation = await ref.read(sharedPreferencesFoundationProvider.future);
  final appBadge = AppBadgeCounter(sharedPreferencesFoundation);

  onLogout(ref, appBadge.clearAllBadges);

  return appBadge;
}

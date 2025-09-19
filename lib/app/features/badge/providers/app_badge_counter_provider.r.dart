// SPDX-License-Identifier: ice License 1.0

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_badge_counter_provider.r.g.dart';

class AppBadgeCounter {
  AppBadgeCounter(this.sharedPreferencesFoundation);

  final SharedPreferencesAsync sharedPreferencesFoundation;

  Future<void> setBadgeCount(int count) async {
    if (await AppBadgePlus.isSupported()) {
      await Future.wait([
        _cacheBadgeCount(count),
        AppBadgePlus.updateBadge(count),
      ]);
    }
  }

  Future<void> clearBadge() async {
    if (await AppBadgePlus.isSupported()) {
      await Future.wait([
        _cacheBadgeCount(0),
        AppBadgePlus.updateBadge(0),
      ]);
    }
  }

  Future<void> _cacheBadgeCount(int count) async {
    await sharedPreferencesFoundation.setInt(_storeKey, count);
  }

  static const String _storeKey = 'app_badge_count';
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

  onLogout(ref, appBadge.clearBadge);

  return appBadge;
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/core/providers/app_info_provider.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_review_controller.r.g.dart';

@riverpod
class AppReviewController extends _$AppReviewController {
  static const _keyLastVersion = 'review_last_version';
  static const _keyCloseCount = 'review_close_count';
  static const _keyIsCompleted = 'review_is_completed';

  @override
  void build() {}

  Future<bool> shouldShowReview() async {
    final packageInfo = await ref.watch(appInfoProvider.future);
    final localStorage = ref.read(localStorageProvider);

    final currentVersion = packageInfo.version;
    final lastVersion = localStorage.getString(_keyLastVersion);
    final isCompleted = localStorage.getBool(_keyIsCompleted) ?? false;
    final closeCount = localStorage.getInt(_keyCloseCount) ?? 0;

    // 1. FIRST INSTALL LOGIC
    // If lastVersion is null, it's the first time they ever open or install this version of the app.
    if (lastVersion == null) {
      await localStorage.setString(_keyLastVersion, currentVersion);
      return false;
    }

    // 2. NEW RELEASE LOGIC
    // If version changed, reset the counts and allow showing it.
    if (lastVersion != currentVersion) {
      await localStorage.setString(_keyLastVersion, currentVersion);
      await localStorage.setBool(key: _keyIsCompleted, value: false);
      await localStorage.setInt(_keyCloseCount, 0);
      return true;
    }

    // Don't show if already rated/feedback given or closed 3 times
    if (isCompleted || closeCount >= 3) return false;

    return true;
  }

  Future<void> recordDismiss() async {
    final localStorage = ref.read(localStorageProvider);
    final count = (localStorage.getInt(_keyCloseCount) ?? 0) + 1;
    await localStorage.setInt(_keyCloseCount, count);
  }

  Future<void> recordComplete() async {
    final localStorage = ref.read(localStorageProvider);
    await localStorage.setBool(key: _keyIsCompleted, value: true);
  }

  Future<void> debugReset() async {
    final localStorage = ref.read(localStorageProvider);
    await localStorage.remove(_keyLastVersion);
    await localStorage.remove(_keyCloseCount);
    await localStorage.remove(_keyIsCompleted);

    await localStorage.setString(_keyLastVersion, 'debug');
  }
}

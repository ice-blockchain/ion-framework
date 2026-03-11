// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/core/providers/app_info_provider.r.dart';
import 'package:ion/app/features/core/providers/date_time_now_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_review_controller.r.g.dart';

@riverpod
class AppReviewController extends _$AppReviewController {
  // Storage keys
  static const _keyLastVersion = 'review_last_version';
  static const _keyCloseCount = 'review_close_count';
  static const _keyStarRating = 'review_star_rating';
  static const _keyLaunchTimes = 'review_launch_times';
  static const _keyRemindInterval = 'review_remind_interval';

  // Thresholds
  static const int _minLaunchTimes = 2;
  static const int _minDaysAfterInstall = 2;
  static const int _maxCloseCount = 3;
  static const int _minDaysBeforeRemind = 1;
  static const String _debugTag = 'debug';

  static const int _dayMs = 24 * 60 * 60 * 1000;

  // Cache for localStorage to avoid repeated reads
  LocalStorage get _storage => ref.read(localStorageProvider);

  DateTime get _now => ref.read(dateTimeNowProvider);

  @override
  void build() {}

  /// Main method: should show review prompt to user?
  Future<bool> shouldShowReview() async {
    final version = (await ref.read(appInfoProvider.future)).version;
    final lastVersion = _storage.getString(_keyLastVersion);

    Logger.info('[AppReview] version: $version, last: $lastVersion, '
        'completed: $_isCompleted [${_storage.getInt(_keyStarRating)}]');

    // First launch - init but don't prompt
    if (lastVersion == null) {
      await _storage.setString(_keyLastVersion, version);
      return false;
    }

    if (lastVersion != version) {
      await _applicationWasLaunched();

      final isMeetConditions = await _checkNewVersionConditions();
      // App updated - reset counters only if user meet NewVersionConditions
      if (isMeetConditions) {
        await _resetForNewVersion(version);
        await _resetRemindDate();
      }
    }

    // Same version - check interval conditions
    return _shouldShow();
  }

  Future<bool> _checkNewVersionConditions() async {
    // Check engagement thresholds: enough launches AND enough time since install (persists across re installs)
    final installTime = (await ref.read(appInfoProvider.future)).installTime;
    final daysSinceInstall = installTime != null
        ? _now.difference(installTime).inDays
        : -1; // if no install time, treat as new user

    Logger.info('[AppReview] installTime: $installTime, daysSinceInstall: $daysSinceInstall, '
        '_launchCount: $_launchCount');

    return _launchCount >= _minLaunchTimes && daysSinceInstall >= _minDaysAfterInstall;
  }

  /// Interval conditions check: reminder, close count, completion status
  Future<bool> _shouldShow() async {
    final isOverRemindDate = _isOverRemindDate();
    Logger.info('[AppReview] _closeCount: $_closeCount, isOverRemindDate: $isOverRemindDate');

    // Too many dismissals or already completed
    if (_closeCount >= _maxCloseCount || _isCompleted) return false;

    if (!isOverRemindDate) return false;
    await _resetRemindDate();

    return true;
  }

  /// Reset state for new app version
  Future<void> _resetForNewVersion(String version) async {
    await _storage.setString(_keyLastVersion, version);
    await _storage.remove(_keyCloseCount);
    await _storage.remove(_keyLaunchTimes);
    if (!_isReviewSend) {
      await _storage.remove(_keyStarRating);
    }
  }

  /// User dismissed the prompt
  Future<void> recordDismiss() async {
    await _storage.setInt(_keyCloseCount, _closeCount + 1);
  }

  /// User completed/gave review
  Future<void> recordComplete(int reviewRating) async {
    await _storage.setInt(_keyStarRating, reviewRating);
  }

  /// Reset for debugging
  Future<void> debugReset() async {
    await _storage.remove(_keyCloseCount);
    await _storage.remove(_keyStarRating);
    await _storage.remove(_keyLaunchTimes);
    await _storage.setInt(
      _keyRemindInterval,
      _now.add(const Duration(days: _minDaysBeforeRemind)).millisecondsSinceEpoch,
    );
    await _storage.setString(_keyLastVersion, _debugTag);
  }

  /// Track app launch
  Future<void> _applicationWasLaunched() async {
    await _setLaunchCount(_launchCount + 1);
  }

  bool get _isCompleted => (_storage.getInt(_keyStarRating) ?? 0) > 0;

  bool get _isReviewSend => (_storage.getInt(_keyStarRating) ?? 0) >= 5;

  int get _closeCount => _storage.getInt(_keyCloseCount) ?? 0;

  int get _launchCount => _storage.getInt(_keyLaunchTimes) ?? 0;

  bool _isOverRemindDate() {
    final remindDate = _storage.getInt(_keyRemindInterval);
    return remindDate != null &&
        _now.millisecondsSinceEpoch - remindDate >= _minDaysBeforeRemind * _dayMs;
  }

  Future<void> _resetRemindDate() async {
    return _storage.setInt(_keyRemindInterval, _now.millisecondsSinceEpoch);
  }

  Future<void> _setLaunchCount(int count) async {
    await _storage.setInt(_keyLaunchTimes, count);
  }
}

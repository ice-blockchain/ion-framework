// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/app_info_provider.r.dart';
import 'package:ion/app/features/core/providers/date_time_now_provider.r.dart';
import 'package:ion/app/services/review/app_review_controller.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../../test_utils.dart';

void main() {
  const testVersion = '1.0.0';
  const newVersion = '2.0.0';

  late LocalStorage localStorage;

  setUp(() async {
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    localStorage = LocalStorage(prefs);
  });

  /// Creates a container with optional mock time.
  ProviderContainer createTestContainer({
    DateTime? mockTime,
    String version = testVersion,
    DateTime? mockInstallTime,
    List<Override>? overrides,
  }) {
    return createContainer(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
        appInfoProvider.overrideWith((_) async => _MockPackageInfo(version, mockInstallTime)),
        if (mockTime != null) dateTimeNowProvider.overrideWith((ref) => mockTime),
        ...?overrides,
      ],
    );
  }

  group('AppReviewController', () {
    group('shouldShowReview - First Install', () {
      test('returns false on first install (no lastVersion), saves version', () async {
        final c = createTestContainer();
        final result = await c.read(appReviewControllerProvider.notifier).shouldShowReview();

        expect(result, isFalse);
        expect(localStorage.getString('review_last_version'), testVersion);
        // launchCount should NOT be set on first install
        expect(localStorage.getInt('review_launch_times'), isNull);
        // remindDate should NOT be set on first install
        expect(localStorage.getInt('review_remind_interval'), isNull);
      });
    });

    group('shouldShowReview - Same Version', () {
      test('returns true when version same (no version change, just check conditions)', () async {
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        final twoDaysAgo = now.subtract(const Duration(days: 2));

        // Last version stored with remindDate set
        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_remind_interval', twoDaysAgo.millisecondsSinceEpoch);

        final c = createTestContainer(
          mockTime: now,
          mockInstallTime: threeDaysAgo,
        );

        final result = await c.read(appReviewControllerProvider.notifier).shouldShowReview();

        // remindDate passed (>1 day), closeCount=0, no rating -> should show
        expect(result, isTrue);
      });

      test('returns false when same version and remindDate not passed yet (< 1 day)', () async {
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        final oneHourAgo = now.subtract(const Duration(hours: 1));

        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_remind_interval', oneHourAgo.millisecondsSinceEpoch);

        final c = createTestContainer(
          mockTime: now,
          mockInstallTime: threeDaysAgo,
        );

        final result = await c.read(appReviewControllerProvider.notifier).shouldShowReview();

        expect(result, isFalse);
      });

      test('resets remindDate after showing', () async {
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        final twoDaysAgo = now.subtract(const Duration(days: 2));

        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_remind_interval', twoDaysAgo.millisecondsSinceEpoch);

        final c = createTestContainer(
          mockTime: now,
          mockInstallTime: threeDaysAgo,
        );

        final result = await c.read(appReviewControllerProvider.notifier).shouldShowReview();

        expect(result, isTrue);
        // remindDate should be reset to now
        expect(localStorage.getInt('review_remind_interval'), isNotNull);
      });
    });

    group('shouldShowReview - Version Changed', () {
      test('version changed: increments launchCount, checks conditions, sets remindDate if met',
          () async {
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));

        // Old version stored
        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_launch_times', 5);
        await localStorage.setInt('review_close_count', 2);

        // New version in provider + install time 3 days ago (meets conditions: >=2 launches, >=2 days)
        final c = createTestContainer(
          version: newVersion,
          mockTime: now,
          mockInstallTime: threeDaysAgo,
        );

        final result = await c.read(appReviewControllerProvider.notifier).shouldShowReview();

        // Conditions met (launchTimes >= 2, days >= 2), so:
        // - version updated
        expect(localStorage.getString('review_last_version'), newVersion);
        // - launchCount reset
        expect(localStorage.getInt('review_launch_times'), isNull);
        // - closeCount reset
        expect(localStorage.getInt('review_close_count'), isNull);
        // - remindDate set
        expect(localStorage.getInt('review_remind_interval'), isNotNull);
        // Result is false because remindDate was just set (need to wait 1 day)
        expect(result, isFalse);
      });

      test(
          'version changed but conditions NOT met: version NOT updated, counters NOT reset, remindDate NOT set',
          () async {
        final now = DateTime.now();

        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_launch_times', 1); // not enough (need >=2)
        await localStorage.setInt('review_close_count', 2);

        // New version but install time is too recent (3 days, but minDaysAfterInstall=2, so this should pass actually)
        // Let's use 1 day to fail the condition
        final oneDayAgo = now.subtract(const Duration(days: 1));

        final c = createTestContainer(
          version: newVersion,
          mockTime: now,
          mockInstallTime: oneDayAgo, // only 1 day, needs 2
        );

        final result = await c.read(appReviewControllerProvider.notifier).shouldShowReview();

        expect(result, isFalse);
        // version NOT updated (conditions not met)
        expect(localStorage.getString('review_last_version'), testVersion);
        // launchCount incremented but NOT reset (conditions not met) - 1 + 1 = 2
        expect(localStorage.getInt('review_launch_times'), 2);
        // closeCount NOT reset (conditions not met)
        expect(localStorage.getInt('review_close_count'), 2);
        // remindDate should NOT be set (conditions not met)
        expect(localStorage.getInt('review_remind_interval'), isNull);
      });

      test('version changed: rating < 5 is cleared', () async {
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));

        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_launch_times', 5);
        await localStorage.setInt('review_star_rating', 3); // < 5, should be cleared on new version

        final c = createTestContainer(
          version: newVersion,
          mockTime: now,
          mockInstallTime: threeDaysAgo,
        );

        await c.read(appReviewControllerProvider.notifier).shouldShowReview();

        // Rating should be cleared for new version (since < 5)
        expect(localStorage.getInt('review_star_rating'), isNull);
      });

      test('version changed: rating = 5 is preserved (never reset)', () async {
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));

        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_launch_times', 5);
        await localStorage.setInt('review_star_rating', 5); // 5 stars - keep it

        final c = createTestContainer(
          version: newVersion,
          mockTime: now,
          mockInstallTime: threeDaysAgo,
        );

        await c.read(appReviewControllerProvider.notifier).shouldShowReview();

        expect(localStorage.getInt('review_star_rating'), 5);
      });
    });

    group('shouldShowReview - Rating/Close Logic', () {
      test('returns false when rating > 0 (any rating < 5 means user already rated)', () async {
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        final twoDaysAgo = now.subtract(const Duration(days: 2));

        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_remind_interval', twoDaysAgo.millisecondsSinceEpoch);
        await localStorage.setInt('review_star_rating', 3); // rated, but not 5

        final c = createTestContainer(
          mockTime: now,
          mockInstallTime: threeDaysAgo,
        );

        final result = await c.read(appReviewControllerProvider.notifier).shouldShowReview();

        // _isCompleted = rating > 0, so no show
        expect(result, isFalse);
      });

      test('returns false when rating = 5 (sent to stores, never show again)', () async {
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        final twoDaysAgo = now.subtract(const Duration(days: 2));

        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_remind_interval', twoDaysAgo.millisecondsSinceEpoch);
        await localStorage.setInt('review_star_rating', 5); // 5 stars = sent to stores

        final c = createTestContainer(
          mockTime: now,
          mockInstallTime: threeDaysAgo,
        );

        final result = await c.read(appReviewControllerProvider.notifier).shouldShowReview();

        expect(result, isFalse);
      });

      test('returns false when close count >= 3', () async {
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        final twoDaysAgo = now.subtract(const Duration(days: 2));

        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_remind_interval', twoDaysAgo.millisecondsSinceEpoch);
        await localStorage.setInt('review_close_count', 3); // max allowed

        final c = createTestContainer(
          mockTime: now,
          mockInstallTime: threeDaysAgo,
        );

        final result = await c.read(appReviewControllerProvider.notifier).shouldShowReview();

        expect(result, isFalse);
      });

      test('returns true when no rating, closeCount < 3, remindDate passed', () async {
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        final twoDaysAgo = now.subtract(const Duration(days: 2));

        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_remind_interval', twoDaysAgo.millisecondsSinceEpoch);
        await localStorage.setInt('review_close_count', 1);

        final c = createTestContainer(
          mockTime: now,
          mockInstallTime: threeDaysAgo,
        );

        final result = await c.read(appReviewControllerProvider.notifier).shouldShowReview();

        expect(result, isTrue);
      });
    });

    group('recordDismiss', () {
      test('increments close count by 1', () async {
        await localStorage.setString('review_last_version', testVersion);
        final c = createTestContainer();

        await c.read(appReviewControllerProvider.notifier).recordDismiss();

        expect(localStorage.getInt('review_close_count'), 1);
      });

      test('increments from existing value', () async {
        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_close_count', 2);
        final c = createTestContainer();

        await c.read(appReviewControllerProvider.notifier).recordDismiss();

        expect(localStorage.getInt('review_close_count'), 3);
      });
    });

    group('recordComplete', () {
      test('sets star rating', () async {
        await localStorage.setString('review_last_version', testVersion);
        final c = createTestContainer();

        await c.read(appReviewControllerProvider.notifier).recordComplete(4);

        expect(localStorage.getInt('review_star_rating'), 4);
      });

      test('sets rating 5', () async {
        await localStorage.setString('review_last_version', testVersion);
        final c = createTestContainer();

        await c.read(appReviewControllerProvider.notifier).recordComplete(5);

        expect(localStorage.getInt('review_star_rating'), 5);
      });
    });

    group('debugReset', () {
      test('clears closeCount, starRating, launchTimes, sets debug version and remindInterval',
          () async {
        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_close_count', 2);
        await localStorage.setInt('review_star_rating', 3);
        await localStorage.setInt('review_launch_times', 5);
        await localStorage.setInt('review_remind_interval', DateTime.now().millisecondsSinceEpoch);

        final now = DateTime.now();
        final c = createTestContainer(mockTime: now);

        await c.read(appReviewControllerProvider.notifier).debugReset();

        expect(localStorage.getString('review_last_version'), 'debug');
        expect(localStorage.getInt('review_close_count'), isNull);
        expect(localStorage.getInt('review_star_rating'), isNull);
        expect(localStorage.getInt('review_launch_times'), isNull);
        // remindInterval is set to now + _minDaysBeforeRemind (1 day)
        final remindInterval = localStorage.getInt('review_remind_interval');
        expect(remindInterval, isNotNull);
        expect(remindInterval! - now.millisecondsSinceEpoch, closeTo(24 * 60 * 60 * 1000, 1000));
      });
    });
  });
}

class _MockPackageInfo implements PackageInfo {
  const _MockPackageInfo(this.version, [this._installTime]);

  @override
  final String version;

  final DateTime? _installTime;

  @override
  String get buildNumber => '';

  @override
  String get buildSignature => '';

  @override
  String get appName => '';

  @override
  String get packageName => '';

  @override
  String get installerStore => '';

  @override
  Map<String, dynamic> get data => {};

  @override
  DateTime? get installTime => _installTime;

  @override
  DateTime? get updateTime => null;
}

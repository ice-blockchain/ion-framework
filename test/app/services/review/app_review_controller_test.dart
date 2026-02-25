// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/app_info_provider.r.dart';
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

  late ProviderContainer container;

  setUp(() {
    container = createContainer(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
        appInfoProvider.overrideWith((_) async => const _MockPackageInfo(testVersion)),
      ],
    );
  });

  group('AppReviewController', () {
    group('shouldShowReview', () {
      test('returns false on first install (no lastVersion)', () async {
        final result =
            await container.read(appReviewControllerProvider.notifier).shouldShowReview();

        expect(result, isFalse);
        expect(localStorage.getString('review_last_version'), testVersion);
      });

      test('returns true when version changed', () async {
        await localStorage.setString('review_last_version', testVersion);
        final testContainer = createContainer(
          overrides: [
            localStorageProvider.overrideWithValue(localStorage),
            appInfoProvider.overrideWith((_) async => const _MockPackageInfo(newVersion)),
          ],
        );

        final result =
            await testContainer.read(appReviewControllerProvider.notifier).shouldShowReview();

        expect(result, isTrue);
      });

      test('returns false when already completed', () async {
        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setBool(key: 'review_is_completed', value: true);

        final result =
            await container.read(appReviewControllerProvider.notifier).shouldShowReview();

        expect(result, isFalse);
      });

      test('returns false when closed max times', () async {
        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_close_count', 3);

        final result =
            await container.read(appReviewControllerProvider.notifier).shouldShowReview();

        expect(result, isFalse);
      });

      test('returns true when version same and not completed and not max close count', () async {
        await localStorage.setString('review_last_version', testVersion);

        final result =
            await container.read(appReviewControllerProvider.notifier).shouldShowReview();

        expect(result, isTrue);
      });
    });

    group('recordDismiss', () {
      test('increments close count', () async {
        await localStorage.setString('review_last_version', testVersion);

        await container.read(appReviewControllerProvider.notifier).recordDismiss();

        expect(localStorage.getInt('review_close_count'), 1);
      });
    });

    group('recordComplete', () {
      test('sets isCompleted to true', () async {
        await localStorage.setString('review_last_version', testVersion);

        await container.read(appReviewControllerProvider.notifier).recordComplete();

        expect(localStorage.getBool('review_is_completed'), isTrue);
      });
    });

    group('debugReset', () {
      test('clears all keys and sets debug version', () async {
        await localStorage.setString('review_last_version', testVersion);
        await localStorage.setInt('review_close_count', 2);
        await localStorage.setBool(key: 'review_is_completed', value: true);

        await container.read(appReviewControllerProvider.notifier).debugReset();

        expect(localStorage.getString('review_last_version'), 'debug');
        expect(localStorage.getInt('review_close_count'), isNull);
        expect(localStorage.getBool('review_is_completed'), isNull);
      });
    });
  });
}

class _MockPackageInfo implements PackageInfo {
  const _MockPackageInfo(this.version);

  @override
  final String version;

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
  DateTime? get installTime => null;

  @override
  DateTime? get updateTime => null;
}

// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/feed/data/models/feed_config.f.dart';
import 'package:ion/app/features/feed/data/models/feed_interests.f.dart';
import 'package:ion/app/features/feed/providers/feed_user_interest_picker_provider.r.dart';
import 'package:mocktail/mocktail.dart';

class MockRandom extends Mock implements Random {}

void main() {
  group('FeedUserInterestPicker', () {
    late FeedConfig config;
    late FeedInterests interests;
    late Random random;

    setUp(() {
      config = const FeedConfig(
        version: 0,
        interestedThreshold: 0.5,
        notInterestedCategoryChance: 0.5,
        followingReqMaxAge: Duration(days: 1),
        followingCacheMaxAge: Duration(days: 2),
        topMaxAge: Duration(days: 1),
        trendingMaxAge: Duration(days: 1),
        exploreMaxAge: Duration(days: 1),
        tokenizedCommunitiesMaxAge: Duration(days: 1),
        repostThrottleDelay: Duration(days: 1),
        concurrentRequests: 3,
        concurrentMediaDownloadsLimit: 3,
        concurrentBigFileUploadChunks: 5,
        excludeUnclassifiedFromExplore: false,
        forYouMaxRetriesMultiplier: 5,
        followingMaxRetriesMultiplier: 5,
        forYouOverflowMultiplier: 2,
        nsfwBlockThreshold: 0.5,
        langDetectScoreThreshold: 0.9,
        cdnBaseUrl: '',
        forYouSeenSkipsMultiplier: 0.5,
      );
      interests = FeedInterests.fromJson({
        'music': {
          'weight': 2,
          'display': 'Music',
          'children': {
            'rock': {'weight': 10, 'display': 'Rock'},
            'pop': {'weight': 1, 'display': 'Pop'},
          },
        },
        'sports': {
          'weight': 10,
          'display': 'Sports',
          'children': {
            'basketball': {'weight': 2, 'display': 'Basketball'},
            'football': {'weight': 5, 'display': 'Football'},
          },
        },
      });
      random = MockRandom();

      when(() => random.nextDouble()).thenReturn(Random().nextDouble());
      when(() => random.nextInt(any(that: isA<int>()))).thenAnswer((invocation) {
        final n = invocation.positionalArguments.first as int;
        if (n <= 0) {
          throw ArgumentError.value(n, 'n', 'Must be positive');
        }
        return 0;
      });
    });

    test('rolls a random category', () {
      final picker = FeedUserInterestPicker(
        config: config.copyWith(notInterestedCategoryChance: 1),
        interests: interests,
        random: random,
      );
      final result = picker.roll();
      expect(result, equals('music'));
    });

    test('rolls a random category from interested category', () {
      final picker = FeedUserInterestPicker(
        config: config.copyWith(
          notInterestedCategoryChance: 0,
        ),
        interests: interests,
        random: random,
      );
      final result = picker.roll();
      expect(result, equals('sports'));
    });

    test('rolls only from allowedCategories if provided', () {
      final picker = FeedUserInterestPicker(
        config: config.copyWith(
          notInterestedCategoryChance: 1,
        ),
        interests: interests,
        random: random,
      );
      final result = picker.roll(['music', 'science']);
      expect(result, equals('music'));
    });

    test('rolls null if no allowed provided', () {
      final picker = FeedUserInterestPicker(
        config: config.copyWith(
          notInterestedCategoryChance: 1,
        ),
        interests: interests,
        random: random,
      );
      final result = picker.roll(['foo']);
      expect(result, isNull);
    });

    test(
        'rolls a random category from allowedCategories if there are no interested categories and interested chance is 100%',
        () {
      final picker = FeedUserInterestPicker(
        config: config.copyWith(
          notInterestedCategoryChance: 0,
          interestedThreshold: 1,
        ),
        interests: interests,
        random: random,
      );
      final result = picker.roll(['music', 'sports']);
      expect(result, equals('music'));
    });
  });
}

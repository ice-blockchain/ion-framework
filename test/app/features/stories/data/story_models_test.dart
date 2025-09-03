// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/feed/stories/data/models/models.dart';

import '../../../../fixtures/posts/post_fixtures.dart';

void main() {
  final userA = buildPost('a1');
  final userB = buildPost('b1', author: 'bob');

  group('SingleUserStoriesViewerState navigation getters', () {
    test('hasPreviousStory behaves at boundaries', () {
      var singleState = const SingleUserStoriesViewerState(
        pubkey: 'alice',
        currentStoryIndex: 0,
      );
      expect(singleState.hasPreviousStory, isFalse);

      singleState = singleState.copyWith(currentStoryIndex: 1);
      expect(singleState.hasPreviousStory, isTrue);
    });
  });

  group('UserStoriesViewerState navigation getters', () {
    test('hasNextUser / hasPreviousUser behave at boundaries', () {
      var multiState = UserStoriesViewerState(
        userStories: [userA, userB],
        currentUserIndex: 0,
      );
      expect(multiState.hasNextUser, isTrue);
      expect(multiState.hasPreviousUser, isFalse);

      multiState = multiState.copyWith(currentUserIndex: 1);
      expect(multiState.hasNextUser, isFalse);
      expect(multiState.hasPreviousUser, isTrue);
    });
  });

  group('UserStoriesViewerState current getters', () {
    test('currentStory & currentUserPubkey return correct values', () {
      final multiState = UserStoriesViewerState(
        userStories: [userA, userB],
        currentUserIndex: 1,
      );

      expect(multiState.currentStory?.id, equals('b1'));
      expect(multiState.currentUserPubkey, equals('bob'));
    });

    test('currentStory returns null when index is out of range', () {
      final multiState = UserStoriesViewerState(
        userStories: [userA],
        currentUserIndex: 5,
      );

      expect(multiState.currentStory, isNull);
    });

    test('nextUserPubkey returns correct pubkey or empty string', () {
      var multiState = UserStoriesViewerState(
        userStories: [userA, userB],
        currentUserIndex: 0,
      );
      expect(multiState.nextUserPubkey, equals('bob'));

      multiState = multiState.copyWith(currentUserIndex: 1);
      expect(multiState.nextUserPubkey, isNull);
    });

    test('pubkeyAtIndex returns pubkey or empty string', () {
      final multiState = UserStoriesViewerState(
        userStories: [userA, userB],
        currentUserIndex: 0,
      );
      expect(multiState.pubkeyAtIndex(1), equals('bob'));
      expect(multiState.pubkeyAtIndex(5), isNull);
    });
  });
}

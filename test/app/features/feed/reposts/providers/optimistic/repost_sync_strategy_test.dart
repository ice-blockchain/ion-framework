// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/feed/reposts/models/post_repost.f.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/repost_sync_strategy.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateRepostFunction extends Mock {
  Future<EventReference> call(EventReference ref);
}

class MockDeleteRepostFunction extends Mock {
  Future<void> call(EventReference ref);
}

class MockInvalidateCacheFunction extends Mock {
  void call(EventReference ref);
}

class MockUpdateRepostCacheFunction extends Mock {
  void call(EventReference ref, int delta);
}

void main() {
  group('RepostSyncStrategy', () {
    late MockCreateRepostFunction mockCreateRepost;
    late MockDeleteRepostFunction mockDeleteRepost;
    late MockInvalidateCacheFunction mockInvalidateCache;
    late MockUpdateRepostCacheFunction mockUpdateRepostCache;
    late RepostSyncStrategy strategy;

    const eventRef = ImmutableEventReference(
      masterPubkey: 'pubkey42',
      eventId: '42',
      kind: 1,
    );

    const myRepostRef = ReplaceableEventReference(
      kind: 16,
      masterPubkey: 'testPubkey',
      dTag: 'testTag',
    );

    setUp(() {
      mockCreateRepost = MockCreateRepostFunction();
      mockDeleteRepost = MockDeleteRepostFunction();
      mockInvalidateCache = MockInvalidateCacheFunction();
      mockUpdateRepostCache = MockUpdateRepostCacheFunction();
      strategy = RepostSyncStrategy(
        createRepost: mockCreateRepost.call,
        deleteRepost: mockDeleteRepost.call,
        invalidateCounterCache: mockInvalidateCache.call,
        updateRepostCache: mockUpdateRepostCache.call,
      );

      registerFallbackValue(eventRef);
    });

    group('delete repost scenarios', () {
      test('handles EntityNotFoundException as successful deletion with zero count', () async {
        const previous = PostRepost(
          eventReference: eventRef,
          repostsCount: 1,
          quotesCount: 0,
          repostedByMe: true,
          myRepostReference: myRepostRef,
        );

        const optimistic = PostRepost(
          eventReference: eventRef,
          repostsCount: 0,
          quotesCount: 0,
          repostedByMe: false,
        );

        when(() => mockDeleteRepost.call(myRepostRef)).thenThrow(EntityNotFoundException('test'));

        final result = await strategy.send(previous, optimistic);

        expect(result.repostedByMe, isFalse);
        expect(result.myRepostReference, isNull);
        expect(result.repostsCount, 0);

        verifyNever(() => mockUpdateRepostCache.call(eventRef, -1));
      });

      test('handles EntityNotFoundException with non-zero count', () async {
        const previous = PostRepost(
          eventReference: eventRef,
          repostsCount: 5,
          quotesCount: 0,
          repostedByMe: true,
          myRepostReference: myRepostRef,
        );

        const optimistic = PostRepost(
          eventReference: eventRef,
          repostsCount: 4,
          quotesCount: 0,
          repostedByMe: false,
        );

        when(() => mockDeleteRepost.call(myRepostRef)).thenThrow(EntityNotFoundException('test'));

        final result = await strategy.send(previous, optimistic);

        expect(result.repostedByMe, isFalse);
        expect(result.myRepostReference, isNull);
        expect(result.repostsCount, 4);

        verifyNever(() => mockInvalidateCache.call(eventRef));
        verify(() => mockUpdateRepostCache.call(eventRef, -1)).called(1);
      });

      test('rethrows other exceptions', () async {
        const previous = PostRepost(
          eventReference: eventRef,
          repostsCount: 1,
          quotesCount: 0,
          repostedByMe: true,
          myRepostReference: myRepostRef,
        );

        const optimistic = PostRepost(
          eventReference: eventRef,
          repostsCount: 0,
          quotesCount: 0,
          repostedByMe: false,
        );

        when(() => mockDeleteRepost.call(myRepostRef)).thenThrow(Exception('Network error'));

        expect(
          () => strategy.send(previous, optimistic),
          throwsA(isA<Exception>()),
        );

        verifyNever(() => mockInvalidateCache.call(any()));
      });

      test('successful delete with zero count', () async {
        const previous = PostRepost(
          eventReference: eventRef,
          repostsCount: 1,
          quotesCount: 0,
          repostedByMe: true,
          myRepostReference: myRepostRef,
        );

        const optimistic = PostRepost(
          eventReference: eventRef,
          repostsCount: 0,
          quotesCount: 0,
          repostedByMe: false,
        );

        when(() => mockDeleteRepost.call(myRepostRef)).thenAnswer((_) async {});

        final result = await strategy.send(previous, optimistic);

        expect(result.repostedByMe, isFalse);
        expect(result.myRepostReference, isNull);
        expect(result.repostsCount, 0);

        verify(() => mockInvalidateCache.call(eventRef)).called(1);
        verifyNever(() => mockUpdateRepostCache.call(eventRef, -1));
      });
    });

    group('create repost scenarios', () {
      test('successful create', () async {
        const createdRef = ReplaceableEventReference(
          kind: 16,
          masterPubkey: 'newPubkey',
          dTag: 'newTag',
        );

        const previous = PostRepost(
          eventReference: eventRef,
          repostsCount: 0,
          quotesCount: 0,
          repostedByMe: false,
        );

        const optimistic = PostRepost(
          eventReference: eventRef,
          repostsCount: 1,
          quotesCount: 0,
          repostedByMe: true,
        );

        when(() => mockCreateRepost.call(eventRef)).thenAnswer((_) async => createdRef);

        final result = await strategy.send(previous, optimistic);

        expect(result.repostedByMe, isTrue);
        expect(result.myRepostReference, createdRef);
        expect(result.repostsCount, 1);

        verify(() => mockUpdateRepostCache.call(eventRef, 1)).called(1);
      });

      test('create failure throws exception', () async {
        const previous = PostRepost(
          eventReference: eventRef,
          repostsCount: 0,
          quotesCount: 0,
          repostedByMe: false,
        );

        const optimistic = PostRepost(
          eventReference: eventRef,
          repostsCount: 1,
          quotesCount: 0,
          repostedByMe: true,
        );

        when(() => mockCreateRepost.call(eventRef)).thenThrow(Exception('Create failed'));

        expect(
          () => strategy.send(previous, optimistic),
          throwsA(isA<Exception>()),
        );

        verifyNever(() => mockInvalidateCache.call(any()));
      });
    });

    test('no action when states are the same', () async {
      const state = PostRepost(
        eventReference: eventRef,
        repostsCount: 5,
        quotesCount: 2,
        repostedByMe: true,
        myRepostReference: myRepostRef,
      );

      final result = await strategy.send(state, state);

      expect(result, state);

      verifyNever(() => mockCreateRepost.call(any()));
      verifyNever(() => mockDeleteRepost.call(any()));
      verifyNever(() => mockInvalidateCache.call(any()));
    });
  });
}

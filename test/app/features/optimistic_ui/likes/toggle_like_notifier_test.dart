// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/providers/counters/like_reaction_provider.r.dart';
import 'package:ion/app/features/feed/providers/counters/likes_count_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/optimistic_ui/database/dao/user_sent_likes_dao.m.dart';
import 'package:ion/app/features/optimistic_ui/database/tables/user_sent_likes_table.d.dart';
import 'package:ion/app/features/optimistic_ui/features/likes/like_sync_strategy_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/features/likes/model/post_like.f.dart';
import 'package:ion/app/features/optimistic_ui/features/likes/post_like_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/features/likes/toggle_like_intent.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../test_utils.dart';

class _MockSyncStrategy extends Mock implements SyncStrategy<PostLike> {}

class _MockUserSentLikesDao extends Mock implements UserSentLikesDao {}

class _FakeCurrentPubkeySelector extends CurrentPubkeySelector {
  _FakeCurrentPubkeySelector(this._pubkey);

  final String? _pubkey;

  @override
  String? build() => _pubkey;
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(ToggleLikeIntent());
    registerFallbackValue(
      const ImmutableEventReference(
        masterPubkey: 'test',
        eventId: 'test',
        kind: 1,
      ),
    );
    registerFallbackValue(UserSentLikeStatus.pending);
    registerFallbackValue(
      const PostLike(
        eventReference: ImmutableEventReference(
          masterPubkey: 'test',
          eventId: 'test',
          kind: 1,
        ),
        likesCount: 0,
        likedByMe: false,
      ),
    );
  });

  group('ToggleLikeNotifier', () {
    late _MockSyncStrategy mockSyncStrategy;
    late _MockUserSentLikesDao mockDao;

    const eventRef = ImmutableEventReference(
      masterPubkey: 'pubkey123',
      eventId: 'event123',
      kind: 1,
    );

    setUp(() {
      mockSyncStrategy = _MockSyncStrategy();
      mockDao = _MockUserSentLikesDao();
      // When the sync strategy sends a reaction, mimic a successful backend
      // response by returning the optimistic state (the second argument) rather
      // than a constant PostLike. Using a fixed PostLike here can lead to a
      // mismatch between the optimistic state and the backend state, causing
      // the OptimisticOperationManager to schedule an additional sync and
      // resulting in unexpected extra calls. Returning the provided next
      // PostLike ensures the backend state matches the optimistic one and
      // avoids unnecessary follow‑up syncs.
      when(() => mockSyncStrategy.send(any(), any())).thenAnswer(
        (invocation) async => invocation.positionalArguments[1] as PostLike,
      );
      when(() => mockDao.hasUserLiked(any())).thenAnswer((_) async => false);
      when(
        () => mockDao.insertOrUpdateLike(
          eventReference: any(named: 'eventReference'),
          status: any(named: 'status'),
          sentAt: any(named: 'sentAt'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockDao.deleteLike(any())).thenAnswer((_) async {});
      when(
        () => mockDao.updateLikeStatus(
          eventReference: any(named: 'eventReference'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async {});
    });

    test(
      'allows toggle operations for different content simultaneously',
      () async {
        const eventRef2 = ImmutableEventReference(
          masterPubkey: 'pubkey456',
          eventId: 'event456',
          kind: 1,
        );

        final container = createContainer(
          overrides: [
            currentPubkeySelectorProvider
                .overrideWith(() => _FakeCurrentPubkeySelector('testPubkey')),
            userSentLikesDaoProvider.overrideWithValue(mockDao),
            likeSyncStrategyProvider.overrideWithValue(mockSyncStrategy),
            postLikeWatchProvider(eventRef.toString()).overrideWith(
              (ref) => Stream.value(
                const PostLike(
                  eventReference: eventRef,
                  likesCount: 5,
                  likedByMe: true,
                ),
              ),
            ),
            postLikeWatchProvider(eventRef2.toString()).overrideWith(
              (ref) => Stream.value(
                const PostLike(
                  eventReference: eventRef2,
                  likesCount: 3,
                  likedByMe: true,
                ),
              ),
            ),
            likesCountProvider(eventRef).overrideWithValue(5),
            likesCountProvider(eventRef2).overrideWithValue(3),
            isLikedProvider(eventRef).overrideWithValue(true),
            isLikedProvider(eventRef2).overrideWithValue(true),
          ],
        );

        final notifier = container.read(toggleLikeNotifierProvider.notifier);

        final future1 = notifier.toggle(eventRef);
        final future2 = notifier.toggle(eventRef2);

        await Future.wait([future1, future2]);

        verify(() => mockSyncStrategy.send(any(), any())).called(2);
      },
    );

    test(
      'allows subsequent toggle after debounce period',
      () async {
        final container = createContainer(
          overrides: [
            currentPubkeySelectorProvider
                .overrideWith(() => _FakeCurrentPubkeySelector('testPubkey')),
            userSentLikesDaoProvider.overrideWithValue(mockDao),
            likeSyncStrategyProvider.overrideWithValue(mockSyncStrategy),
            postLikeWatchProvider(eventRef.toString()).overrideWith(
              (ref) => Stream.value(
                const PostLike(
                  eventReference: eventRef,
                  likesCount: 5,
                  likedByMe: true,
                ),
              ),
            ),
            likesCountProvider(eventRef).overrideWithValue(5),
            isLikedProvider(eventRef).overrideWithValue(true),
          ],
        );

        final notifier = container.read(toggleLikeNotifierProvider.notifier);

        await notifier.toggle(eventRef);
        verify(() => mockSyncStrategy.send(any(), any())).called(1);

        unawaited(notifier.toggle(eventRef));
        await Future<void>.delayed(const Duration(milliseconds: 350));
        await notifier.toggle(eventRef);

        verify(() => mockSyncStrategy.send(any(), any())).called(2);
      },
    );

    test('debounce delay is at least 300ms', () async {
      final container = createContainer(
        overrides: [
          currentPubkeySelectorProvider
              .overrideWith(() => _FakeCurrentPubkeySelector('testPubkey')),
          userSentLikesDaoProvider.overrideWithValue(mockDao),
          likeSyncStrategyProvider.overrideWithValue(mockSyncStrategy),
          postLikeWatchProvider(eventRef.toString()).overrideWith(
            (ref) => Stream.value(
              const PostLike(
                eventReference: eventRef,
                likesCount: 5,
                likedByMe: true,
              ),
            ),
          ),
          likesCountProvider(eventRef).overrideWithValue(5),
          isLikedProvider(eventRef).overrideWithValue(true),
        ],
      );

      final notifier = container.read(toggleLikeNotifierProvider.notifier);

      final stopwatch = Stopwatch()..start();

      await notifier.toggle(eventRef);

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(300));
    });
  });
}

// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/reposts/models/post_repost.f.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/post_repost_provider.r.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/repost_sync_strategy_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../mocks.dart';
import '../../../../../test_utils.dart';
import '../../helpers/repost_test_helpers.dart';
import '../mocks/repost_mocks.dart';

void main() {
  setUpAll(registerRepostFallbackValues);

  group('Post repost providers integration', () {
    const testPubkey = RepostTestConstants.currentUserPubkey;
    const postRef1 = ImmutableEventReference(
      masterPubkey: 'author1',
      eventId: 'post1',
      kind: 1,
    );
    const postRef2 = ImmutableEventReference(
      masterPubkey: 'author2',
      eventId: 'post2',
      kind: 1,
    );
    const repostRef1 = ImmutableEventReference(
      masterPubkey: RepostTestConstants.currentUserPubkey,
      eventId: 'repost1',
      kind: GenericRepostEntity.kind,
    );

    late Env mockEnv;

    setUp(() {
      mockEnv = MockEnv();

      when(() => mockEnv.get<bool>(EnvVariable.OPTIMISTIC_UI_ENABLED)).thenReturn(true);
    });

    test('finds specific repost in cache', () async {
      final cacheData = {
        repostRef1.toString(): CacheEntry(
          entity: GenericRepostEntity(
            id: repostRef1.toString(),
            masterPubkey: testPubkey,
            pubkey: testPubkey,
            signature: 'sig1',
            createdAt: 1234567890,
            data: const GenericRepostData(
              kind: GenericRepostEntity.kind,
              eventReference: postRef1,
            ),
          ),
          createdAt: DateTime.now(),
        ),
      };

      final container = createContainer(
        overrides: [
          currentPubkeySelectorProvider.overrideWith(() => FakeCurrentPubkeySelector(testPubkey)),
          ionConnectCacheProvider.overrideWith(() => FakeIonConnectCache(cacheData)),
          envProvider.overrideWith(() => mockEnv),
        ],
      );

      final result = container.read(findRepostInCacheProvider(postRef1));

      expect(result, isNotNull);
      expect(result!.eventReference, postRef1);
      expect(result.repostedByMe, true);
      expect(result.myRepostReference?.toString(), repostRef1.toString());

      final notFound = container.read(findRepostInCacheProvider(postRef2));
      expect(notFound, isNull);
    });

    test('loads reposts from cache correctly', () async {
      final cacheData = {
        repostRef1.toString(): CacheEntry(
          entity: GenericRepostEntity(
            id: repostRef1.toString(),
            masterPubkey: testPubkey,
            pubkey: testPubkey,
            signature: 'sig1',
            createdAt: 1234567890,
            data: const GenericRepostData(
              kind: GenericRepostEntity.kind,
              eventReference: postRef1,
            ),
          ),
          createdAt: DateTime.now(),
        ),
      };

      final container = createContainer(
        overrides: [
          currentPubkeySelectorProvider.overrideWith(() => FakeCurrentPubkeySelector(testPubkey)),
          ionConnectCacheProvider.overrideWith(() => FakeIonConnectCache(cacheData)),
          envProvider.overrideWith(() => mockEnv),
        ],
      );

      final result = container.read(loadRepostsFromCacheProvider);

      expect(result.length, 1);
      final item = result.first;

      expect(item.eventReference, postRef1);
      expect(item.repostedByMe, true);
      expect(item.myRepostReference?.toString(), repostRef1.toString());
    });

    test('merges OptimisticService state with cache data', () async {
      final mockSyncStrategy = MockRepostSyncStrategy();
      when(() => mockSyncStrategy.send(any(), any())).thenAnswer(
        (invocation) async => invocation.positionalArguments[1] as PostRepost,
      );

      final container = createContainer(
        overrides: [
          currentPubkeySelectorProvider.overrideWith(() => FakeCurrentPubkeySelector(testPubkey)),
          ionConnectCacheProvider.overrideWith(() => FakeIonConnectCache({})),
          repostSyncStrategyProvider.overrideWith((ref) => mockSyncStrategy),
          envProvider.overrideWith(() => mockEnv),
        ],
      );

      final listener = Listener<AsyncValue<PostRepost?>>();
      container.listen(
        postRepostWatchProvider(postRef2.toString()),
        listener.call,
        fireImmediately: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(toggleRepostNotifierProvider.notifier);
      await notifier.toggle(postRef2);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(
        () => listener(
          any(),
          any(
            that: isA<AsyncValue<PostRepost?>>()
                .having(
                  (s) => s.value?.repostedByMe,
                  'repostedByMe',
                  true,
                )
                .having(
                  (s) => s.value?.eventReference,
                  'eventReference',
                  postRef2,
                ),
          ),
        ),
      ).called(greaterThanOrEqualTo(1));

      verify(() => mockSyncStrategy.send(any(), any())).called(1);
    });

    test('handles cache updates with existing OptimisticService state', () async {
      final mockSyncStrategy = MockRepostSyncStrategy();
      when(() => mockSyncStrategy.send(any(), any())).thenAnswer(
        (invocation) async {
          final previous = invocation.positionalArguments[0] as PostRepost;
          final optimistic = invocation.positionalArguments[1] as PostRepost;

          if (!previous.repostedByMe && optimistic.repostedByMe) {
            return optimistic.copyWith(
              myRepostReference: const ImmutableEventReference(
                masterPubkey: 'test-pubkey-123',
                eventId: 'new-repost',
                kind: GenericRepostEntity.kind,
              ),
            );
          }

          return optimistic;
        },
      );

      final cacheData = {
        repostRef1.toString(): CacheEntry(
          entity: GenericRepostEntity(
            id: repostRef1.toString(),
            masterPubkey: testPubkey,
            pubkey: testPubkey,
            signature: 'sig1',
            createdAt: 1234567890,
            data: const GenericRepostData(
              kind: GenericRepostEntity.kind,
              eventReference: postRef1,
            ),
          ),
          createdAt: DateTime.now(),
        ),
      };

      final container = createContainer(
        overrides: [
          currentPubkeySelectorProvider.overrideWith(() => FakeCurrentPubkeySelector(testPubkey)),
          ionConnectCacheProvider.overrideWith(() => FakeIonConnectCache(cacheData)),
          repostSyncStrategyProvider.overrideWith((ref) => mockSyncStrategy),
          envProvider.overrideWith(() => mockEnv),
        ],
      );

      final listener = Listener<AsyncValue<PostRepost?>>();

      container.listen(
        postRepostWatchProvider(postRef1.toString()),
        listener.call,
        fireImmediately: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Service starts empty - no initial state
      final initialManager = container.read(postRepostManagerProvider);
      expect(initialManager.snapshot.length, 0); // Manager should be empty

      // postRepostWatch should return AsyncValue.data(null) when there's no optimistic state
      final initialState = container.read(postRepostWatchProvider(postRef1.toString()));
      expect(initialState.hasValue, isTrue); // Should have completed
      expect(initialState.value, isNull); // But value should be null

      // Create optimistic state through dispatch (this is the new behavior)
      // First toggle: create repost (since there's cached data, this will un-repost)
      final notifier = container.read(toggleRepostNotifierProvider.notifier);
      await notifier.toggle(postRef1);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // After first toggle, it should be un-reposted (since cached data was reposted)
      final afterFirstToggle = container.read(postRepostWatchProvider(postRef1.toString()));
      expect(afterFirstToggle.hasValue, isTrue);
      expect(afterFirstToggle.value?.repostedByMe, isFalse);

      // Second toggle: create repost
      await notifier.toggle(postRef1);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Now verify the optimistic state was created as reposted
      final optimisticState = container.read(postRepostWatchProvider(postRef1.toString()));
      expect(optimisticState.hasValue, isTrue);
      expect(optimisticState.value?.repostedByMe, isTrue);
      expect(optimisticState.value?.myRepostReference, isNotNull);

      clearInteractions(listener);

      final manager = container.read(postRepostManagerProvider);

      final currentState = container.read(loadRepostsFromCacheProvider).first;

      final undoState = PostRepostFactory.createNotReposted(
        eventReference: currentState.eventReference,
        repostsCount: currentState.repostsCount - 1,
      );

      await manager.perform(
        previous: currentState,
        optimistic: undoState,
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final finalState = container.read(postRepostWatchProvider(postRef1.toString()));

      expect(finalState.hasValue, isTrue);
      expect(finalState.value?.repostedByMe, isFalse);
      expect(finalState.value?.myRepostReference, isNull);

      verify(() => listener(any(), any())).called(greaterThanOrEqualTo(1));
    });

    test('handles no reposts in cache with items in OptimisticService', () async {
      final container = createContainer(
        overrides: [
          currentPubkeySelectorProvider.overrideWith(() => FakeCurrentPubkeySelector(testPubkey)),
          ionConnectCacheProvider.overrideWith(() => FakeIonConnectCache({})),
          envProvider.overrideWith(() => mockEnv),
        ],
      )..read(postRepostServiceProvider);

      final listener = Listener<AsyncValue<PostRepost?>>();
      container.listen(
        postRepostWatchProvider(postRef1.toString()),
        listener.call,
        fireImmediately: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final manager = container.read(postRepostManagerProvider);
      await manager.perform(
        previous: PostRepostFactory.createNotReposted(eventReference: postRef1),
        optimistic: PostRepostFactory.createReposted(
          eventReference: postRef1,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(
        () => listener(
          any(),
          any(
            that: isA<AsyncValue<PostRepost?>>()
                .having(
                  (s) => s.value?.repostedByMe,
                  'repostedByMe',
                  true,
                )
                .having(
                  (s) => s.value?.repostsCount,
                  'repostsCount',
                  1,
                ),
          ),
        ),
      ).called(greaterThanOrEqualTo(1));
    });
  });
}

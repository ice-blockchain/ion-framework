// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/reposts/models/post_repost.f.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/post_repost_provider.r.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/repost_sync_strategy_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../../../mocks.dart';
import '../../../../../../test_utils.dart';
import '../../mocks/repost_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Toggle Repost Race Condition Tests', () {
    const eventRef = ImmutableEventReference(
      masterPubkey: 'pubkey42',
      eventId: '42',
      kind: 1,
    );

    late ProviderContainer container;
    late MockRepostSyncStrategy mockStrategy;
    late Env mockEnv;

    setUpAll(registerRepostFallbackValues);

    setUp(() {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      mockStrategy = MockRepostSyncStrategy();
      mockEnv = MockEnv();

      when(() => mockEnv.get<bool>(EnvVariable.OPTIMISTIC_UI_ENABLED)).thenReturn(true);
      when(() => mockEnv.get<String>(EnvVariable.FOUNDATION_APP_GROUP)).thenReturn('');
      when(() => mockStrategy.send(any(), any())).thenAnswer((invocation) async {
        final optimistic = invocation.positionalArguments[1] as PostRepost;

        await Future<void>.delayed(const Duration(milliseconds: 100));

        if (optimistic.repostedByMe) {
          return optimistic.copyWith(
            myRepostReference: const ReplaceableEventReference(
              kind: 16,
              masterPubkey: 'testPubkey',
              dTag: 'testTag',
            ),
          );
        }

        return optimistic;
      });

      container = createContainer(
        overrides: [
          repostSyncStrategyProvider.overrideWith((_) => mockStrategy),
          envProvider.overrideWith(() => mockEnv),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('handles sequential toggles with delays correctly', () async {
      // Initial state: not reposted
      const initialState = PostRepost(
        eventReference: eventRef,
        repostsCount: 5,
        quotesCount: 3,
        repostedByMe: false,
      );

      await container.read(postRepostServiceProvider).initialize([initialState]);

      final listener = Listener<AsyncValue<PostRepost?>>();
      final subscription = container.listen(
        postRepostWatchProvider(eventRef.toString()),
        listener.call,
        fireImmediately: true,
      );

      final notifier = container.read(toggleRepostNotifierProvider.notifier);

      await notifier.toggle(eventRef);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      await notifier.toggle(eventRef);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      await notifier.toggle(eventRef);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final finalState = subscription.read().value;

      expect(finalState, isNotNull);
      expect(finalState?.repostedByMe, true);
      expect(finalState?.repostsCount, 6);
      expect(finalState?.quotesCount, 3);

      verify(() => mockStrategy.send(any(), any())).called(greaterThanOrEqualTo(3));
    });

    test('optimizes rapid toggles by canceling pending operations', () async {
      const initialState = PostRepost(
        eventReference: eventRef,
        repostsCount: 5,
        quotesCount: 3,
        repostedByMe: false,
      );

      await container.read(postRepostServiceProvider).initialize([initialState]);

      final listener = Listener<AsyncValue<PostRepost?>>();
      final subscription = container.listen(
        postRepostWatchProvider(eventRef.toString()),
        listener.call,
        fireImmediately: true,
      );

      final notifier = container.read(toggleRepostNotifierProvider.notifier);

      final toggle1 = notifier.toggle(eventRef);
      final toggle2 = notifier.toggle(eventRef);
      final toggle3 = notifier.toggle(eventRef);

      await Future.wait([toggle1, toggle2, toggle3]);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final finalState = subscription.read().value;

      expect(finalState, isNotNull);
    });

    test('handles concurrent toggles on different posts independently', () async {
      const eventRef1 = ImmutableEventReference(
        masterPubkey: 'pubkey1',
        eventId: '1',
        kind: 1,
      );

      const eventRef2 = ImmutableEventReference(
        masterPubkey: 'pubkey2',
        eventId: '2',
        kind: 1,
      );

      const state1 = PostRepost(
        eventReference: eventRef1,
        repostsCount: 5,
        quotesCount: 0,
        repostedByMe: false,
      );

      const state2 = PostRepost(
        eventReference: eventRef2,
        repostsCount: 3,
        quotesCount: 1,
        repostedByMe: false,
      );

      await container.read(postRepostServiceProvider).initialize([state1, state2]);

      final subscription1 = container.listen(
        postRepostWatchProvider(eventRef1.toString()),
        (_, __) {},
        fireImmediately: true,
      );

      final subscription2 = container.listen(
        postRepostWatchProvider(eventRef2.toString()),
        (_, __) {},
        fireImmediately: true,
      );

      final notifier = container.read(toggleRepostNotifierProvider.notifier);
      await Future.wait([
        notifier.toggle(eventRef1),
        notifier.toggle(eventRef2),
      ]);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final finalState1 = subscription1.read().value;
      final finalState2 = subscription2.read().value;

      expect(finalState1, isNotNull);
      expect(finalState1?.repostedByMe, true);
      expect(finalState1?.repostsCount, 6);

      expect(finalState2, isNotNull);
      expect(finalState2?.repostedByMe, true);
      expect(finalState2?.repostsCount, 4);

      verify(() => mockStrategy.send(any(), any())).called(greaterThanOrEqualTo(2));
    });

    test('handles error during toggle with rollback', () async {
      final stateChanges = <PostRepost?>[];

      final responses = <Future<PostRepost> Function(Invocation)>[
        (invocation) async {
          final optimistic = invocation.positionalArguments[1] as PostRepost;
          await Future<void>.delayed(const Duration(milliseconds: 50));

          if (optimistic.repostedByMe) {
            return optimistic.copyWith(
              myRepostReference: const ReplaceableEventReference(
                kind: 16,
                masterPubkey: 'testPubkey',
                dTag: 'testTag',
              ),
            );
          }
          return optimistic;
        },
        (invocation) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          throw Exception('Network error');
        },
      ];

      when(() => mockStrategy.send(any(), any()))
          .thenAnswer((invocation) => responses.removeAt(0)(invocation));

      const initialState = PostRepost(
        eventReference: eventRef,
        repostsCount: 5,
        quotesCount: 3,
        repostedByMe: false,
      );

      container = createContainer(
        overrides: [
          repostSyncStrategyProvider.overrideWith((_) => mockStrategy),
          postRepostManagerProvider.overrideWith((ref) {
            final strategy = ref.watch(repostSyncStrategyProvider);
            return OptimisticOperationManager<PostRepost>(
              syncCallback: strategy.send,
              onError: (_, __) async => false,
              enableLocal: true,
              maxRetries: 0,
            );
          }),
        ],
      );

      await container.read(postRepostServiceProvider).initialize([initialState]);

      final listener = Listener<AsyncValue<PostRepost?>>();
      final subscription = container.listen(
        postRepostWatchProvider(eventRef.toString()),
        (previous, next) {
          listener.call(previous, next);
          stateChanges.add(next.value);
        },
        fireImmediately: true,
      );

      final notifier = container.read(toggleRepostNotifierProvider.notifier);
      await notifier.toggle(eventRef);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final intermediateState = subscription.read().value;
      expect(intermediateState?.repostedByMe, true);
      expect(intermediateState?.repostsCount, 6);

      stateChanges.clear();

      await expectLater(
        notifier.toggle(eventRef),
        completes,
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final finalState = subscription.read().value;

      expect(stateChanges.length, greaterThanOrEqualTo(2));
      expect(stateChanges.first?.repostedByMe, false);
      expect(stateChanges.first?.repostsCount, 5);
      expect(finalState, isNotNull);
      expect(finalState?.repostedByMe, true);
      expect(finalState?.repostsCount, 6);
    });

    test('maintains consistency with many sequential toggles', () async {
      const initialState = PostRepost(
        eventReference: eventRef,
        repostsCount: 10,
        quotesCount: 5,
        repostedByMe: false,
      );

      await container.read(postRepostServiceProvider).initialize([initialState]);

      final subscription = container.listen(
        postRepostWatchProvider(eventRef.toString()),
        (_, __) {},
        fireImmediately: true,
      );

      final notifier = container.read(toggleRepostNotifierProvider.notifier);

      for (var i = 0; i < 10; i++) {
        await notifier.toggle(eventRef);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      await Future<void>.delayed(const Duration(milliseconds: 500));

      final finalState = subscription.read().value;

      expect(finalState, isNotNull);
      expect(finalState?.repostedByMe, false);
      expect(finalState?.repostsCount, 10);
      expect(finalState?.repostsCount, greaterThanOrEqualTo(0));
    });

    test('handles rapid toggles with proper state tracking', () async {
      const initialState = PostRepost(
        eventReference: eventRef,
        repostsCount: 0,
        quotesCount: 0,
        repostedByMe: false,
      );

      await container.read(postRepostServiceProvider).initialize([initialState]);

      final states = <PostRepost?>[];
      final listener = Listener<AsyncValue<PostRepost?>>();

      container.listen(
        postRepostWatchProvider(eventRef.toString()),
        (previous, next) {
          listener.call(previous, next);
          states.add(next.value);
        },
        fireImmediately: true,
      );

      final notifier = container.read(toggleRepostNotifierProvider.notifier);

      await notifier.toggle(eventRef);
      await notifier.toggle(eventRef);
      await notifier.toggle(eventRef);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(states.length, greaterThan(1));

      final finalState = states.last;
      expect(finalState, isNotNull);
      expect(finalState?.repostsCount, greaterThanOrEqualTo(0));

      verify(() => listener.call(any(), any())).called(greaterThan(1));
    });

    test('preserves myRepostReference through multiple operations', () async {
      const repostRef = ReplaceableEventReference(
        kind: 16,
        masterPubkey: 'testPubkey',
        dTag: 'originalTag',
      );

      const initialState = PostRepost(
        eventReference: eventRef,
        repostsCount: 5,
        quotesCount: 0,
        repostedByMe: true,
        myRepostReference: repostRef,
      );

      await container.read(postRepostServiceProvider).initialize([initialState]);

      final subscription = container.listen(
        postRepostWatchProvider(eventRef.toString()),
        (_, __) {},
        fireImmediately: true,
      );

      final notifier = container.read(toggleRepostNotifierProvider.notifier);

      await notifier.toggle(eventRef);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final intermediateState = subscription.read().value;
      expect(intermediateState?.repostedByMe, false);
      expect(intermediateState?.myRepostReference, isNull);

      await notifier.toggle(eventRef);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final finalState = subscription.read().value;

      expect(finalState, isNotNull);
      expect(finalState?.repostedByMe, true);
      expect(finalState?.myRepostReference, isNotNull);
      expect(finalState?.repostsCount, 5);
    });
  });
}

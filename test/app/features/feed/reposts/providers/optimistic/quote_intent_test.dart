// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/reposts/models/post_repost.f.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/intents/add_quote_intent.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/intents/remove_quote_intent.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/post_repost_provider.r.dart';
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

  group('Quote Intent Tests', () {
    const eventRef = ImmutableEventReference(
      masterPubkey: 'pubkey123',
      eventId: '123',
      kind: 1,
    );

    late ProviderContainer container;
    late MockRepostSyncStrategy mockStrategy;

    setUpAll(registerRepostFallbackValues);

    setUp(() {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      mockStrategy = MockRepostSyncStrategy();

      when(() => mockStrategy.send(any(), any())).thenAnswer((invocation) async {
        final optimistic = invocation.positionalArguments[1] as PostRepost;
        return optimistic;
      });

      container = createContainer(
        overrides: [
          postRepostManagerProvider.overrideWith((ref) {
            return OptimisticOperationManager<PostRepost>(
              syncCallback: mockStrategy.send,
              onError: (_, __) async => false,
              enableLocal: true,
            );
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('AddQuoteIntent increases quotesCount by 1', () {
      const current = PostRepost(
        eventReference: eventRef,
        repostsCount: 5,
        quotesCount: 3,
        repostedByMe: false,
      );

      const intent = AddQuoteIntent();
      final result = intent.optimistic(current);

      expect(result.quotesCount, 4);
      expect(result.repostsCount, 5);
      expect(result.repostedByMe, false);
    });

    test('RemoveQuoteIntent decreases quotesCount by 1', () {
      const current = PostRepost(
        eventReference: eventRef,
        repostsCount: 5,
        quotesCount: 3,
        repostedByMe: false,
      );

      const intent = RemoveQuoteIntent();
      final result = intent.optimistic(current);

      expect(result.quotesCount, 2);
      expect(result.repostsCount, 5);
      expect(result.repostedByMe, false);
    });

    test('RemoveQuoteIntent does not go below 0', () {
      const current = PostRepost(
        eventReference: eventRef,
        repostsCount: 5,
        quotesCount: 0,
        repostedByMe: false,
      );

      const intent = RemoveQuoteIntent();
      final result = intent.optimistic(current);

      expect(result.quotesCount, 0);
    });

    test('AddQuoteIntent preserves repostedByMe state', () async {
      const initialState = PostRepost(
        eventReference: eventRef,
        repostsCount: 5,
        quotesCount: 2,
        repostedByMe: true,
        myRepostReference: ReplaceableEventReference(
          kind: 16,
          masterPubkey: 'testPubkey',
          dTag: 'testTag',
        ),
      );

      await container.read(postRepostServiceProvider).initialize([initialState]);

      final listener = Listener<AsyncValue<PostRepost?>>();
      final subscription = container.listen(
        postRepostWatchProvider(eventRef.toString()),
        listener.call,
        fireImmediately: true,
      );

      final service = container.read(postRepostServiceProvider);
      await service.dispatch(const AddQuoteIntent(), initialState);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final finalState = subscription.read().value;

      expect(finalState, isNotNull);
      expect(finalState?.quotesCount, 3);
      expect(finalState?.repostedByMe, true);
      expect(finalState?.myRepostReference, isNotNull);
      expect(finalState?.repostsCount, 5);
    });

    test('Quote operations work with non-reposted posts', () async {
      const initialState = PostRepost(
        eventReference: eventRef,
        repostsCount: 10,
        quotesCount: 5,
        repostedByMe: false,
      );

      await container.read(postRepostServiceProvider).initialize([initialState]);

      final listener = Listener<AsyncValue<PostRepost?>>();
      final subscription = container.listen(
        postRepostWatchProvider(eventRef.toString()),
        listener.call,
        fireImmediately: true,
      );

      final service = container.read(postRepostServiceProvider);

      // Add quote
      await service.dispatch(const AddQuoteIntent(), initialState);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      var state = subscription.read().value;
      expect(state?.quotesCount, 6);
      expect(state?.repostedByMe, false);

      // Remove quote
      await service.dispatch(const RemoveQuoteIntent(), state!);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      state = subscription.read().value;
      expect(state?.quotesCount, 5);
      expect(state?.repostedByMe, false);
    });

    test('Multiple quote operations in sequence', () async {
      const initialState = PostRepost(
        eventReference: eventRef,
        repostsCount: 0,
        quotesCount: 0,
        repostedByMe: false,
      );

      await container.read(postRepostServiceProvider).initialize([initialState]);

      final subscription = container.listen(
        postRepostWatchProvider(eventRef.toString()),
        (_, __) {},
        fireImmediately: true,
      );

      final service = container.read(postRepostServiceProvider);

      // Add 3 quotes
      var current = initialState;
      for (var i = 0; i < 3; i++) {
        await service.dispatch(const AddQuoteIntent(), current);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        current = subscription.read().value!;
      }

      expect(current.quotesCount, 3);

      // Remove 2 quotes
      for (var i = 0; i < 2; i++) {
        await service.dispatch(const RemoveQuoteIntent(), current);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        current = subscription.read().value!;
      }

      expect(current.quotesCount, 1);
      expect(current.repostsCount, 0);
    });

    test('Combined repost and quote scenario', () async {
      const initialState = PostRepost(
        eventReference: eventRef,
        repostsCount: 5,
        quotesCount: 2,
        repostedByMe: false,
      );

      await container.read(postRepostServiceProvider).initialize([initialState]);

      final stateChanges = <PostRepost?>[];
      final subscription = container.listen(
        postRepostWatchProvider(eventRef.toString()),
        (previous, next) {
          stateChanges.add(next.value);
        },
        fireImmediately: true,
      );

      final service = container.read(postRepostServiceProvider);
      final toggleNotifier = container.read(toggleRepostNotifierProvider.notifier);

      // First repost the post
      await toggleNotifier.toggle(eventRef);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      var state = subscription.read().value!;
      expect(state.repostedByMe, true);
      expect(state.repostsCount, 6);

      // Then add a quote
      await service.dispatch(const AddQuoteIntent(), state);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      state = subscription.read().value!;
      expect(state.repostedByMe, true);
      expect(state.repostsCount, 6);
      expect(state.quotesCount, 3);

      // Remove the repost
      await toggleNotifier.toggle(eventRef);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      state = subscription.read().value!;
      expect(state.repostedByMe, false);
      expect(state.repostsCount, 5);
      expect(state.quotesCount, 3);

      // Verify total count
      expect(state.totalRepostsCount, 8);
    });

    test('Quote intent sync throws UnimplementedError', () {
      const intent = AddQuoteIntent();
      const current = PostRepost(
        eventReference: eventRef,
        repostsCount: 0,
        quotesCount: 0,
        repostedByMe: false,
      );

      expect(
        () => intent.sync(current, current),
        throwsUnimplementedError,
      );
    });

    test('RemoveQuoteIntent sync throws UnimplementedError', () {
      const intent = RemoveQuoteIntent();
      const current = PostRepost(
        eventReference: eventRef,
        repostsCount: 0,
        quotesCount: 0,
        repostedByMe: false,
      );

      expect(
        () => intent.sync(current, current),
        throwsUnimplementedError,
      );
    });
  });
}

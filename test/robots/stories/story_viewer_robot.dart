// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_viewing_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/user_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/viewed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/core/core.dart';
import 'package:ion/app/features/feed/stories/views/pages/story_viewer_page.dart';
import 'package:ion/app/router/providers/go_router_provider.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:ion/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../app/features/stories/data/fake_feed_stories_state.dart';
import '../../app/features/stories/data/fake_user_stories_provider.dart';
import '../../app/features/stories/data/fake_viewed_stories_controller.dart';
import '../../helpers/robot_test_harness.dart';
import '../../mocks.dart';
import '../base_robot.dart';
import '../mixins/provider_scope_mixin.dart';
import '../mixins/story_state_mixin.dart';

class StoryViewerRobot extends BaseRobot with ProviderScopeMixin, StoryStateMixin {
  StoryViewerRobot(super.tester);

  static Future<StoryViewerRobot> launch(
    WidgetTester tester, {
    required List<ModifiablePostEntity> stories,
    required String viewerPubkey,
    String identity = 'test_user',
    List<Override> extraOverrides = const [],
    bool autoPush = false,
  }) async {
    final robot = StoryViewerRobot(tester);

    final mockStorage = MockLocalStorage();
    when(() => mockStorage.setStringList(any(), any<List<String>>())).thenAnswer((_) async => true);
    when(() => mockStorage.getStringList(any())).thenReturn(null);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        GoRoute(
          path: '/viewer',
          builder: (_, __) => StoryViewerPage(pubkey: viewerPubkey),
        ),
      ],
      initialLocation: '/',
    );

    await tester.pumpWithHarness(
      childBuilder: (_) => const SizedBox(),
      router: router,
      overrides: [
        feedStoriesProvider.overrideWith(() => FakeFeedStories(stories)),
        currentIdentityKeyNameSelectorProvider
            .overrideWith(() => _BackgroundIdentityKeyNameSelector(identity)),
        localStorageProvider.overrideWithValue(mockStorage),
        userPreferencesServiceProvider(identityKeyName: identity)
            .overrideWith((_) => UserPreferencesService(identity, mockStorage)),
        goRouterProvider.overrideWith((_) => router),
        viewedStoriesProvider.overrideWith(FakeViewedStoriesController.new),
        ...extraOverrides,
      ],
      localizationsDelegates: I18n.localizationsDelegates,
      supportedLocales: I18n.supportedLocales,
      locale: const Locale('en'),
    );

    await tester.pumpAndSettle();

    if (autoPush) {
      unawaited(router.push('/viewer'));
      await tester.pumpAndSettle();
    }

    robot.initStoryState(
      pubkey: viewerPubkey,
      providerContainer: robot.getContainerFromKey(storiesSwiperKey),
    );

    return robot;
  }

  Finder get _swiper => find.byKey(storiesSwiperKey);
  Finder get _gesture => find.byKey(Key('story_gesture_$viewerPubkey'));

  Future<void> swipeToNextUser() async {
    await tester.fling(_swiper, const Offset(-600, 0), 1000);
    await tester.pumpAndSettle();
  }

  Future<void> swipeToPreviousUser() async {
    await tester.fling(_swiper, const Offset(600, 0), 1000);
    await tester.pumpAndSettle();
  }

  Future<void> tapNextStory() async {
    await tapRelative(_gesture, dx: 0.75, dy: 0.5);
  }

  Future<void> tapPreviousStory() async {
    await tapRelative(_gesture, dx: 0.25, dy: 0.5);
  }

  // Long press methods
  Future<void> longPressCenter({
    Duration duration = const Duration(milliseconds: 600),
  }) async {
    final gesture = await startPressCenter();
    await tester.pump(duration);
    await releasePress(gesture);
  }

  Future<TestGesture> startPressCenter() async {
    final rect = tester.getRect(_gesture);
    final center = rect.center;
    final gesture = await tester.startGesture(center);
    await tester.pump();
    return gesture;
  }

  Future<void> releasePress(TestGesture gesture) async {
    await gesture.up();
    await tester.pumpAndSettle();
  }

  void expectStoryIndex(int index) {
    expectViewerState(
      userIndex:
          container.read(singleUserStoryViewingControllerProvider(viewerPubkey)).currentStoryIndex,
      storyIndex: index,
    );
  }

  void expectUserIndex(int index) {
    expectViewerState(
      userIndex: index,
      storyIndex: container.read(userStoriesViewingNotifierProvider(viewerPubkey)).currentUserIndex,
    );
  }

  static List<Override> storyViewerOverrides({
    required ModifiablePostEntity post,
    required String pubkey,
  }) {
    final posts = [post];
    return [
      feedStoriesProvider.overrideWith(() => FakeFeedStories(posts)),
      feedStoriesByPubkeyProvider(pubkey).overrideWith((_) => posts),
      userStoriesProvider(pubkey).overrideWith(() => FakeUserStories(posts)),
    ];
  }
}

class _BackgroundIdentityKeyNameSelector extends CurrentIdentityKeyNameSelector {
  _BackgroundIdentityKeyNameSelector(this._identityKeyName);

  final String _identityKeyName;

  @override
  String build() {
    return _identityKeyName;
  }
}

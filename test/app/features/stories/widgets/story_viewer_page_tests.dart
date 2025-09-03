// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/providers/video_player_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_pause_provider.r.dart';
import 'package:ion/app/features/feed/stories/views/pages/story_viewer_page.dart';
import 'package:ion/app/router/providers/go_router_provider.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../../../fixtures/posts/post_fixtures.dart';
import '../../../../fixtures/stories/story_fixtures.dart';
import '../../../../mocks.dart';
import '../../../../robots/stories/story_viewer_robot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  ScreenUtil.ensureScreenSize();

  setUp(() async {
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  const viewerPubkey = StoryFixtures.alice;
  const otherPubkey = StoryFixtures.bob;

  final aliceStories = StoryFixtures.userStory();
  final bobStories = StoryFixtures.userStory(
    pubkey: otherPubkey,
  );

  group('StoryViewerPage – gestures', () {
    testWidgets('horizontal swipe switches user', (tester) async {
      final robot = await StoryViewerRobot.launch(
        tester,
        stories: [aliceStories, bobStories],
        viewerPubkey: viewerPubkey,
      );

      await robot.swipeToNextUser();

      robot.expectUserIndex(1);
    });

    testWidgets('tap right / left switches stories inside user', (tester) async {
      final robot = await StoryViewerRobot.launch(
        tester,
        stories: [aliceStories],
        viewerPubkey: viewerPubkey,
      );

      await robot.tapNextStory();
      robot.expectStoryIndex(1);

      await robot.tapPreviousStory();
      robot.expectStoryIndex(0);
    });

    testWidgets('long-press pauses and resumes after release', (tester) async {
      final robot = await StoryViewerRobot.launch(
        tester,
        stories: [aliceStories],
        viewerPubkey: viewerPubkey,
      );

      final pauseSub = robot.container.listen<bool>(
        storyPauseControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );

      final gesture = await robot.startPressCenter();
      await tester.pump(const Duration(milliseconds: 600));
      expect(pauseSub.read(), isTrue, reason: 'Viewer should be paused');

      await robot.releasePress(gesture);
      expect(pauseSub.read(), isFalse, reason: 'Viewer should be resumed');
    });
  });

  group('StoryViewerPage pops after the very last story', () {
    testWidgets('pops after the very last story', (tester) async {
      const videoDuration = Duration(seconds: 3);
      final lastVideoPost = buildPost('vid_last', mediaType: MediaType.video);
      final fakeCtrl = FakeVideoController(videoDuration);
      VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();

      final mockStorage = MockLocalStorage();
      when(() => mockStorage.getStringList(any())).thenReturn(<String>[]);
      when(() => mockStorage.setStringList(any(), any<List<String>>()))
          .thenAnswer((_) async => true);

      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Scaffold()),
          GoRoute(
            path: '/viewer',
            builder: (_, __) => const StoryViewerPage(pubkey: viewerPubkey),
          ),
        ],
        initialLocation: '/',
      );

      await StoryViewerRobot.launch(
        tester,
        stories: [lastVideoPost],
        viewerPubkey: viewerPubkey,
        autoPush: true,
        extraOverrides: [
          videoPlayerControllerFactoryProvider('dummy')
              .overrideWith((_) => FakeVideoFactory(fakeCtrl)),
          localStorageProvider.overrideWithValue(mockStorage),
          userPreferencesServiceProvider(identityKeyName: viewerPubkey)
              .overrideWith((_) => UserPreferencesService(viewerPubkey, mockStorage)),
          goRouterProvider.overrideWithValue(router),
        ],
      );

      expect(find.byType(StoryViewerPage), findsOneWidget);

      fakeCtrl
        ..value = fakeCtrl.value.copyWith(position: videoDuration)
        ..notifyListeners();

      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(StoryViewerPage), findsNothing);
    });
  });
}

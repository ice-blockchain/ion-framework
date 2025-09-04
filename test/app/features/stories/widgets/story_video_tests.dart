// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/providers/video_player_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/user_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/views/pages/story_viewer_page.dart';
import 'package:ion/app/router/providers/go_router_provider.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../../../fixtures/stories/story_fixtures.dart';
import '../../../../mocks.dart';
import '../../../../robots/stories/story_viewer_robot.dart';
import '../data/fake_user_stories_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  ScreenUtil.ensureScreenSize();

  setUp(() async {
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  const myPubkey = StoryFixtures.alice;
  const otherPubkey = StoryFixtures.bob;

  final myStories = StoryFixtures.userStory();
  final otherStories = StoryFixtures.userStory(
    pubkey: otherPubkey,
  );

  group('Own stories viewer', () {
    testWidgets('horizontal swipe does not switch to another user', (tester) async {
      final robot = await StoryViewerRobot.launch(
        tester,
        stories: [myStories, otherStories],
        viewerPubkey: myPubkey,
        extraOverrides: [
          feedStoriesByPubkeyProvider(myPubkey).overrideWith((_) => [myStories]),
        ],
      );

      robot.expectUserIndex(0);
      await robot.swipeToNextUser();
      robot.expectUserIndex(0);
    });
  });

  const videoDuration = Duration(seconds: 3);
  final myStoriesWithVideo = StoryFixtures.userStory(
    mediaType: MediaType.video,
  );

  final fakeCtrl = FakeVideoController(videoDuration);
  VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();

  final mockStorage = MockLocalStorage();
  when(() => mockStorage.getStringList(any())).thenReturn(<String>[]);
  when(() => mockStorage.setStringList(any(), any<List<String>>())).thenAnswer((_) async => true);

  testWidgets('StoryViewerPage pops after the very last story', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold()),
        GoRoute(
          path: '/viewer',
          builder: (_, __) => const StoryViewerPage(pubkey: myPubkey),
        ),
      ],
      initialLocation: '/',
    );

    final posts = [myStoriesWithVideo];

    await StoryViewerRobot.launch(
      tester,
      stories: posts,
      viewerPubkey: myPubkey,
      autoPush: true,
      extraOverrides: [
        videoPlayerControllerFactoryProvider('dummy')
            .overrideWith((_) => FakeVideoFactory(fakeCtrl)),
        localStorageProvider.overrideWithValue(mockStorage),
        userPreferencesServiceProvider(identityKeyName: myPubkey)
            .overrideWith((_) => UserPreferencesService(myPubkey, mockStorage)),
        userStoriesProvider(myPubkey).overrideWith(() => FakeUserStories(posts)),
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
}

// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/hooks/use_story_progress_controller.dart';
import 'package:ion/app/features/feed/stories/hooks/use_story_video_playback.dart';
import 'package:ion/app/features/feed/stories/providers/story_image_loading_provider.r.dart';

import '../../../../fixtures/stories/story_fixtures.dart';
import '../../../../helpers/robot_test_harness.dart';
import '../../../../mocks.dart';
import '../../../../robots/stories/story_viewer_robot.dart';

class _StoryConsumer extends HookConsumerWidget {
  const _StoryConsumer({required this.post, required this.onCompleted});

  final ModifiablePostEntity post;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useStoryProgressController(
      ref: ref,
      post: post,
      isCurrent: true,
      isPaused: false,
      onCompleted: onCompleted,
    );

    final videoController = ref
        .watch(
          videoControllerProvider(
            const VideoControllerParams(sourcePath: 'dummy', authorPubkey: 'alice'),
          ),
        )
        .valueOrNull;

    useStoryVideoPlayback(
      ref: ref,
      controller: videoController,
      storyId: post.id,
      viewerPubkey: 'alice',
      onCompleted: onCompleted,
    );

    return const SizedBox.shrink();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('useStoryProgressController', () {
    testWidgets('image story completes after 5 s', (tester) async {
      final userStory = StoryFixtures.userStory();
      var completed = false;

      await tester.pumpWithHarness(
        childBuilder: (ref) => _StoryConsumer(
          post: userStory,
          onCompleted: () => completed = true,
        ),
        overrides: StoryViewerRobot.storyViewerOverrides(
          post: userStory,
          pubkey: StoryFixtures.alice,
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(_StoryConsumer)),
      );

      container
          .read(
            storyImageLoadStatusProvider(userStory.id).notifier,
          )
          .markLoaded();

      await tester.pumpAndSettle(const Duration(seconds: 6));
      expect(completed, isTrue);
    });

    testWidgets('video story completes when position == duration', (tester) async {
      const duration = Duration(seconds: 3);
      final userStory = StoryFixtures.userStory(mediaType: MediaType.video);
      final videoController = FakeVideoController(duration);
      var completed = false;

      await tester.pumpWithHarness(
        childBuilder: (ref) => _StoryConsumer(
          post: userStory,
          onCompleted: () => completed = true,
        ),
        overrides: [
          ...StoryViewerRobot.storyViewerOverrides(
            post: userStory,
            pubkey: StoryFixtures.alice,
          ),
          videoPlayerControllerFactoryProvider('dummy')
              .overrideWith((_) => FakeVideoFactory(videoController)),
        ],
      );

      await tester.pump();

      videoController
        ..value = videoController.value.copyWith(position: duration)
        ..notifyListeners();

      await tester.pump(const Duration(milliseconds: 50));

      expect(completed, isTrue);
    });
  });
}

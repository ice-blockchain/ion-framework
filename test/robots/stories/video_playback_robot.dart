// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/hooks/use_story_video_playback.dart';
import 'package:ion/app/features/feed/stories/providers/story_viewing_provider.r.dart';

import '../../helpers/robot_test_harness.dart';
import '../../mocks.dart';
import '../base_robot.dart';
import '../mixins/provider_scope_mixin.dart';
import '../mixins/story_state_mixin.dart';

class _TestVideoPlayback extends HookConsumerWidget {
  const _TestVideoPlayback({required this.post, required this.viewerPubkey});

  final ModifiablePostEntity post;
  final String viewerPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref
        .watch(
          videoControllerProvider(
            const VideoControllerParams(sourcePath: 'dummy', authorPubkey: 'alice'),
          ),
        )
        .valueOrNull;

    useStoryVideoPlayback(
      ref: ref,
      controller: ctrl,
      storyId: post.id,
      viewerPubkey: viewerPubkey,
      onCompleted: () => ref
          .read(singleUserStoryViewingControllerProvider(viewerPubkey).notifier)
          .advance(storiesLength: 0),
    );

    return const SizedBox.shrink();
  }
}

class VideoPlaybackRobot extends BaseRobot with ProviderScopeMixin, StoryStateMixin {
  VideoPlaybackRobot(
    super.tester, {
    required this.post,
    required Duration duration,
  }) : _fake = FakeVideoController(duration);

  final ModifiablePostEntity post;
  final FakeVideoController _fake;

  static Future<VideoPlaybackRobot> launch(
    WidgetTester tester, {
    required ModifiablePostEntity post,
    required String viewerPubkey,
    required Duration duration,
  }) async {
    final robot = VideoPlaybackRobot(
      tester,
      post: post,
      duration: duration,
    );

    await tester.pumpWidget(
      RobotTestHarness(
        childBuilder: (_) => _TestVideoPlayback(
          post: post,
          viewerPubkey: viewerPubkey,
        ),
        overrides: [
          robot.videoOverride,
        ],
      ),
    );

    await tester.pumpAndSettle();

    robot.initStoryState(
      pubkey: viewerPubkey,
      providerContainer: robot.getContainerFromFinder(find.byType(_TestVideoPlayback)),
    );

    return robot;
  }

  Override get videoOverride => videoPlayerControllerFactoryProvider('dummy').overrideWith(
        (_) => FakeVideoFactory(_fake),
      );

  Future<void> completeVideo() async {
    _fake
      ..value = _fake.value.copyWith(position: _fake.value.duration)
      ..notifyListeners();
    await tester.pump();
  }
}

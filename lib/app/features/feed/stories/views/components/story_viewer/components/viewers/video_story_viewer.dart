// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/features/feed/stories/hooks/use_story_video_playback.dart';
import 'package:ion/app/features/feed/stories/providers/story_video_controller_provider.m.dart';
import 'package:video_player/video_player.dart';

class VideoStoryViewer extends HookConsumerWidget {
  const VideoStoryViewer({
    required this.videoPath,
    required this.authorPubkey,
    required this.storyId,
    required this.viewerPubkey,
    required this.onVideoCompleted,
    super.key,
  });

  final String videoPath;
  final String authorPubkey;
  final String storyId;
  final String viewerPubkey;
  final VoidCallback onVideoCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseParams = VideoControllerParams(
      sourcePath: videoPath,
      authorPubkey: authorPubkey,
      uniqueId: storyId,
    );

    final videoController = ref
        .watch(
          storyVideoControllerProvider(
            StoryVideoControllerParams(
              storyId: storyId,
              sessionPubkey: viewerPubkey,
              baseParams: baseParams,
            ),
          ),
        )
        .valueOrNull;

    if (videoController == null || !videoController.value.isInitialized) {
      return const CenteredLoadingIndicator();
    }

    useStoryVideoPlayback(
      ref: ref,
      controller: videoController,
      storyId: storyId,
      viewerPubkey: viewerPubkey,
      onCompleted: onVideoCompleted,
    );

    final aspect = videoController.value.aspectRatio;
    final isHorizontal = aspect > 1.0;
    if (isHorizontal) {
      return Center(
        child: AspectRatio(
          aspectRatio: aspect,
          child: VideoPlayer(videoController),
        ),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: videoController.value.size.width,
          height: videoController.value.size.height,
          child: VideoPlayer(videoController),
        ),
      ),
    );
  }
}

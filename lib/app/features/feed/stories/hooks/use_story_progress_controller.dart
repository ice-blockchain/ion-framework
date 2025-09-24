// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/hooks/use_story_image_progress.dart';
import 'package:ion/app/features/feed/stories/providers/story_video_controller_provider.m.dart';
import 'package:video_player/video_player.dart';

class StoryProgressControllerResult {
  StoryProgressControllerResult({
    required this.mediaType,
    this.imageController,
    this.videoController,
  });

  final AnimationController? imageController;
  final VideoPlayerController? videoController;
  final MediaType mediaType;
}

StoryProgressControllerResult useStoryProgressController({
  required WidgetRef ref,
  required ModifiablePostEntity post,
  required bool isCurrent,
  required bool isPaused,
  required VoidCallback onCompleted,
  String? sessionPubkey,
}) {
  final media = post.data.primaryMedia;
  final mediaType = media?.mediaType ?? MediaType.unknown;

  final isImage = mediaType == MediaType.image;
  final isVideo = mediaType == MediaType.video;

  final image = useImageStoryProgress(
    isImage: isImage,
    storyId: post.id,
    isCurrent: isCurrent,
    isPaused: isPaused,
    onCompleted: onCompleted,
    ref: ref,
  );

  VideoPlayerController? video;
  if (isVideo && isCurrent) {
    final baseParams = VideoControllerParams(
      sourcePath: media!.url,
      authorPubkey: post.masterPubkey,
      uniqueId: post.id,
    );
    final session = sessionPubkey;
    if (session != null) {
      video = ref
          .watch(
            storyVideoControllerProvider(
              StoryVideoControllerParams(
                storyId: post.id,
                sessionPubkey: session,
                baseParams: baseParams,
              ),
            ),
          )
          .valueOrNull;
    } else {
      video = ref.watch(videoControllerProvider(baseParams)).valueOrNull;
    }
  }

  return StoryProgressControllerResult(
    mediaType: mediaType,
    imageController: image.controller,
    videoController: video,
  );
}

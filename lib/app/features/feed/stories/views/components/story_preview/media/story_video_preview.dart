// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/video_player_provider.r.dart';
import 'package:ion/app/hooks/use_auto_play.dart';
import 'package:video_player/video_player.dart';

class StoryVideoPreview extends HookConsumerWidget {
  const StoryVideoPreview({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoController = ref
        .watch(
          videoControllerProvider(
            VideoControllerParams(sourcePath: path, looping: true),
          ),
        )
        .valueOrNull;
    useAutoPlay(videoController);

    if (videoController == null || !videoController.value.isInitialized) {
      return const CenteredLoadingIndicator();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(22.0.s),
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxWidth / videoController.value.aspectRatio,
            child: VideoPlayer(videoController),
          ),
        );
      },
    );
  }
}

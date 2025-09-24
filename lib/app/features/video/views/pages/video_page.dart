// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/video/views/components/video_button.dart';
import 'package:ion/app/features/video/views/components/video_not_found.dart';
import 'package:ion/app/features/video/views/components/video_progress.dart';
import 'package:ion/app/features/video/views/components/video_slider.dart';
import 'package:ion/app/features/video/views/components/video_thumbnail_preview.dart';
import 'package:ion/app/features/video/views/hooks/use_play_button.dart';
import 'package:ion/app/features/video/views/hooks/use_toggle_video_on_lifecycle_change.dart';
import 'package:ion/app/features/video/views/hooks/use_toggle_video_on_route_change.dart';
import 'package:ion/app/hooks/use_auto_play.dart';
import 'package:ion/app/services/media_service/aspect_ratio.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoPage extends HookConsumerWidget {
  const VideoPage({
    required this.videoUrl,
    this.authorPubkey,
    this.looping = true,
    this.framedEventReference,
    this.videoInfo,
    this.bottomOverlay,
    this.videoBottomPadding = 42.0,
    this.thumbnailUrl,
    this.blurhash,
    this.aspectRatio,
    this.playerController,
    this.hideBottomOverlay = false,
    super.key,
  });

  final String videoUrl;
  final String? authorPubkey;
  final EventReference? framedEventReference;
  final bool looping;
  final Widget? videoInfo;
  final Widget? bottomOverlay;
  final double videoBottomPadding;
  final String? thumbnailUrl;
  final String? blurhash;
  final double? aspectRatio;
  final VideoPlayerController? playerController;
  final bool hideBottomOverlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (videoUrl.isEmpty) {
      return const VideoNotFound();
    }

    final playerController = this.playerController ??
        ref
            .watch(
              videoControllerProvider(
                VideoControllerParams(
                  sourcePath: videoUrl,
                  authorPubkey: authorPubkey,
                  looping: looping,
                  uniqueId: framedEventReference?.encode() ?? '',
                ),
              ),
            )
            .valueOrNull;

    useAutoPlay(this.playerController == null ? playerController : null);
    useToggleVideoOnRouteChange(playerController);
    useToggleVideoOnLifecycleChange(ref, playerController);

    final (:showPlayButton, :onTogglePlay) = usePlayButton(ref, playerController);

    return _VisibilityPlayPause(
      playerController: playerController,
      visibilityKey: ValueKey(videoUrl),
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: !hideBottomOverlay ? videoBottomPadding.s : 0),
        child: Stack(
          children: [
            // Showing thumbnail with loading indicator underneath the video player for better UX (no flickering on transition)
            Center(
              child: _VideoThumbWidget(
                authorPubkey: authorPubkey,
                aspectRatio: aspectRatio,
                thumbnailUrl: thumbnailUrl,
                blurhash: blurhash,
              ),
            ),
            const CenteredLoadingIndicator(),
            if (playerController != null) ...[
              if (playerController.value.isInitialized)
                GestureDetector(
                  onTap: onTogglePlay,
                  child: Center(
                    child: _VideoPlayerWidget(controller: playerController),
                  ),
                ),
              if (showPlayButton) Center(child: _PlayButton(controller: playerController)),
              if (!hideBottomOverlay) ...[
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      if (videoInfo != null) videoInfo!,
                      _VideoProgressSlider(controller: playerController),
                      if (bottomOverlay != null) bottomOverlay!,
                    ],
                  ),
                ),
              ],
              const _BottomNotch(),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoThumbWidget extends StatelessWidget {
  const _VideoThumbWidget({
    required this.thumbnailUrl,
    required this.aspectRatio,
    required this.blurhash,
    required this.authorPubkey,
  });

  final String? authorPubkey;
  final double? aspectRatio;
  final String? thumbnailUrl;
  final String? blurhash;

  @override
  Widget build(BuildContext context) {
    final thumbnailAspectRatio = aspectRatio ?? MediaAspectRatio.landscape;

    final Widget thumbnailWidget = VideoThumbnailPreview(
      thumbnailUrl: thumbnailUrl,
      blurhash: blurhash,
      authorPubkey: authorPubkey,
      aspectRatio: thumbnailAspectRatio,
    );

    if (thumbnailAspectRatio < 1) {
      return ClipRect(
        child: OverflowBox(
          maxHeight: double.infinity,
          child: AspectRatio(
            aspectRatio: thumbnailAspectRatio,
            child: thumbnailWidget,
          ),
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: thumbnailAspectRatio,
        child: thumbnailWidget,
      );
    }
  }
}

class _VideoPlayerWidget extends StatelessWidget {
  const _VideoPlayerWidget({
    required this.controller,
  });

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final videoWidget = VideoPlayer(controller);

    if (controller.value.aspectRatio < 1) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.fitWidth,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: videoWidget,
          ),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: videoWidget,
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.controller,
  });

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return VideoButton(
      size: 48.0.s,
      borderRadius: BorderRadius.circular(20.0.s),
      icon: Assets.svg.iconVideoPlay.icon(
        color: context.theme.appColors.secondaryBackground,
        size: 30.0.s,
      ),
      onPressed: controller.play,
    );
  }
}

class _VisibilityPlayPause extends StatelessWidget {
  const _VisibilityPlayPause({
    required this.playerController,
    required this.child,
    required this.visibilityKey,
  });

  final Key visibilityKey;
  final VideoPlayerController? playerController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: visibilityKey,
      onVisibilityChanged: _onVisibilityChanges,
      child: child,
    );
  }

  void _onVisibilityChanges(VisibilityInfo info) {
    final controller = playerController;
    if (controller != null) {
      if (info.visibleFraction <= 0.5) {
        if (controller.value.isInitialized && controller.value.isPlaying) {
          controller.pause();
        }
      } else if (controller.value.isInitialized && controller.value.isPlaying == false) {
        controller.play();
      }
    }
  }
}

class _VideoProgressSlider extends StatelessWidget {
  const _VideoProgressSlider({
    required this.controller,
  });

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return VideoProgress(
      controller: controller,
      builder: (context, position, duration) => VideoSlider(
        position: position,
        duration: duration,
        onChangeStart: (_) => controller.pause(),
        onChangeEnd: (_) => controller.play(),
        onChanged: (value) {
          if (controller.value.isInitialized) {
            controller.seekTo(
              Duration(milliseconds: value.toInt()),
            );
          }
        },
      ),
    );
  }
}

class _BottomNotch extends StatelessWidget {
  const _BottomNotch();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ColoredBox(
        color: context.theme.appColors.primaryText,
        child: SizedBox(
          height: MediaQuery.paddingOf(context).bottom,
          width: double.infinity,
        ),
      ),
    );
  }
}

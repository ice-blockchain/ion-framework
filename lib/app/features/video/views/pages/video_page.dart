// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/core/providers/video_player_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/video/views/components/video_button.dart';
import 'package:ion/app/features/video/views/components/video_not_found.dart';
import 'package:ion/app/features/video/views/components/video_progress.dart';
import 'package:ion/app/features/video/views/components/video_slider.dart';
import 'package:ion/app/features/video/views/components/video_thumbnail_preview.dart';
import 'package:ion/app/hooks/use_auto_play.dart';
import 'package:ion/app/hooks/use_route_presence.dart';
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

    if (playerController == null || !playerController.value.isInitialized) {
      final thumbnailAspectRatio = aspectRatio ?? MediaAspectRatio.landscape;

      Widget thumbnailWidget = Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: !hideBottomOverlay ? videoBottomPadding.s : 0,
        ),
        child: VideoThumbnailPreview(
          thumbnailUrl: thumbnailUrl,
          blurhash: blurhash,
          authorPubkey: authorPubkey,
        ),
      );

      if (thumbnailAspectRatio < 1) {
        thumbnailWidget = ClipRect(
          child: OverflowBox(
            maxHeight: double.infinity,
            child: AspectRatio(
              aspectRatio: thumbnailAspectRatio,
              child: thumbnailWidget,
            ),
          ),
        );
      } else {
        thumbnailWidget = Center(
          child: AspectRatio(
            aspectRatio: thumbnailAspectRatio,
            child: thumbnailWidget,
          ),
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          thumbnailWidget,
          const CenteredLoadingIndicator(),
        ],
      );
    }

    final isPlaying = useState(playerController.value.isPlaying);

    useEffect(
      () {
        void listener() {
          isPlaying.value = playerController.value.isPlaying;
        }

        playerController.addListener(listener);
        return () => playerController.removeListener(listener);
      },
      [playerController],
    );

    useRoutePresence(
      onBecameInactive: () {
        if (playerController.value.isPlaying) {
          playerController.pause();
        }
      },
      onBecameActive: () {
        if (playerController.value.isInitialized && !playerController.value.isPlaying) {
          playerController.play();
        }
      },
    );

    ref.listen(appLifecycleProvider, (_, current) {
      if (!context.mounted) return;

      if (current == AppLifecycleState.resumed) {
        playerController.play();
      } else if (current == AppLifecycleState.paused || current == AppLifecycleState.hidden) {
        playerController.pause();
      }
    });

    final videoPlayer = _VideoPlayerWidget(controller: playerController);

    return VisibilityDetector(
      key: ValueKey(videoUrl),
      onVisibilityChanged: (info) {
        if (info.visibleFraction <= 0.5) {
          if (playerController.value.isInitialized && playerController.value.isPlaying) {
            playerController.pause();
          }
        } else if (playerController.value.isInitialized &&
            playerController.value.isPlaying == false) {
          playerController.play();
        }
      },
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (isPlaying.value) {
                playerController.pause();
              } else {
                playerController.play();
              }
            },
            child: Center(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  bottom: !hideBottomOverlay ? videoBottomPadding.s : 0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: videoPlayer,
                ),
              ),
            ),
          ),
          if (!isPlaying.value)
            Center(
              child: VideoButton(
                size: 48.0.s,
                borderRadius: BorderRadius.circular(20.0.s),
                icon: Assets.svg.iconVideoPlay.icon(
                  color: context.theme.appColors.secondaryBackground,
                  size: 30.0.s,
                ),
                onPressed: playerController.play,
              ),
            ),
          if (!hideBottomOverlay)
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  if (videoInfo != null) videoInfo!,
                  VideoProgress(
                    controller: playerController,
                    builder: (context, position, duration) => VideoSlider(
                      position: position,
                      duration: duration,
                      onChangeStart: (_) => playerController.pause(),
                      onChangeEnd: (_) => playerController.play(),
                      onChanged: (value) {
                        if (playerController.value.isInitialized) {
                          playerController.seekTo(
                            Duration(milliseconds: value.toInt()),
                          );
                        }
                      },
                    ),
                  ),
                  if (bottomOverlay != null) bottomOverlay!,
                ],
              ),
            ),
          if (!hideBottomOverlay)
            Align(
              alignment: Alignment.bottomCenter,
              child: ColoredBox(
                color: context.theme.appColors.primaryText,
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom,
                  width: double.infinity,
                ),
              ),
            ),
        ],
      ),
    );
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

// SPDX-License-Identifier: ice License 1.0

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/placeholder/ion_placeholder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_network_image/ion_connect_network_image.dart';
import 'package:ion/app/features/core/providers/mute_provider.r.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/features/feed/providers/feed_video_playback_enabled.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/settings/providers/video_settings_provider.m.dart';
import 'package:ion/app/features/video/views/components/video_button.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/hooks/use_route_presence.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/app/utils/url.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoPreview extends HookConsumerWidget {
  const VideoPreview({
    required this.videoUrl,
    required this.authorPubkey,
    this.thumbnailUrl,
    this.duration,
    this.onlyOneShouldPlay = true,
    this.framedEventReference,
    this.visibilityThreshold = 1.0,
    super.key,
  });

  final bool onlyOneShouldPlay;
  final String videoUrl;
  final String authorPubkey;
  final String? thumbnailUrl;
  final Duration? duration;
  final EventReference? framedEventReference;
  final double visibilityThreshold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uniqueId = useRef(UniqueKey().toString());
    final videoSettings = ref.watch(videoSettingsProvider);

    final isVideoPlaybackEnabled = ref.watch(feedVideoPlaybackEnabledNotifierProvider);

    // If autoplay is disabled, we don't need to initialize the controller (to avoid the video downloading)
    final videoControllerProviderState = (videoSettings.autoplay && isVideoPlaybackEnabled)
        ? ref.watch(
            videoControllerProvider(
              VideoControllerParams(
                sourcePath: videoUrl,
                authorPubkey: authorPubkey,
                looping: true,
                uniqueId: framedEventReference?.encode() ?? '',
                onlyOneShouldPlay: onlyOneShouldPlay,
              ),
            ),
          )
        : const AsyncValue.data(null);
    final controller = videoControllerProviderState.valueOrNull;

    final isFullyVisible = useState(false);
    final isRouteFocused = useState(true);
    useRoutePresence(
      onBecameInactive: () {
        if (context.mounted) {
          ref.read(feedVideoPlaybackEnabledNotifierProvider.notifier).disablePlayback();
          // Save the current position of the video
          if (controller != null) {
            ref
                .read(videoPlayerPositionDataProvider.notifier)
                .savePosition(videoUrl, controller.value.position.inMilliseconds);
          }
          isRouteFocused.value = false;
        }
      },
      onBecameActive: () {
        if (context.mounted) {
          ref.read(feedVideoPlaybackEnabledNotifierProvider.notifier).enablePlayback();
          isRouteFocused.value = true;
        }
      },
    );

    final isMuted = ref.watch(globalMuteNotifierProvider);

    final handleVisibilityChanged = useCallback(
      (VisibilityInfo info) {
        if (context.mounted) {
          isFullyVisible.value = info.visibleFraction >= visibilityThreshold;
        }
      },
      [isFullyVisible, context, visibilityThreshold],
    );

    useOnInit(
      () {
        if (controller == null || !controller.value.isInitialized) {
          return;
        }
        final shouldBeActive = isFullyVisible.value && isRouteFocused.value;
        if (shouldBeActive && !controller.value.isPlaying) {
          controller.play();
        } else if (!shouldBeActive && controller.value.isPlaying) {
          controller.pause();
        }
      },
      [isFullyVisible.value, isRouteFocused.value, controller],
    );

    useEffect(
      () {
        if (controller != null && controller.value.isInitialized) {
          final isPlaying = controller.value.isPlaying;
          controller.setVolume(isMuted ? 0.0 : 1.0).then((_) {
            // If it was playing before volume change, ensure it's still playing
            if (isPlaying && !controller.value.isPlaying) {
              controller.play();
            }
          });
        }
        return null;
      },
      [isMuted, controller],
    );

    useEffect(
      () {
        if (controller != null && controller.value.isInitialized) {
          controller.setVolume(isMuted ? 0.0 : 1.0);
        }
        return null;
      },
      [controller?.value.isInitialized],
    );

    final hasError =
        controller != null && controller.value.hasError || videoControllerProviderState.hasError;

    return VisibilityDetector(
      key: ValueKey(uniqueId),
      onVisibilityChanged: handleVisibilityChanged,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: context.theme.appColors.primaryBackground),
          ),
          if (thumbnailUrl != null)
            Positioned.fill(
              child: videoControllerProviderState.isLoading
                  ? _LoadingThumbnail(url: thumbnailUrl!, authorPubkey: authorPubkey)
                  : _Thumbnail(url: thumbnailUrl!, authorPubkey: authorPubkey),
            ),
          if (controller != null && controller.value.isInitialized && !hasError)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          if (hasError) const Positioned.fill(child: IonPlaceholder()),
          if (!videoSettings.autoplay) const Center(child: _PlayButton()),
          PositionedDirectional(
            bottom: 12.0.s,
            start: 12.0.s,
            end: 12.0.s,
            child: _VideoControls(controller: controller, duration: duration, isMuted: isMuted),
          ),
        ],
      ),
    );
  }
}

class _VideoControls extends ConsumerWidget {
  const _VideoControls({required this.controller, required this.duration, required this.isMuted});

  final VideoPlayerController? controller;

  final Duration? duration;

  final bool isMuted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (controller != null && controller!.value.isInitialized)
          _VideoControllerDurationLabel(controller: controller!)
        else if (duration != null && duration != Duration.zero)
          _VideoDurationLabel(duration: duration!)
        else
          const SizedBox.shrink(),
        _MuteButton(
          isMuted: isMuted,
          onToggle: ref.read(globalMuteNotifierProvider.notifier).toggle,
        ),
      ],
    );
  }
}

class _VideoControllerDurationLabel extends StatelessWidget {
  const _VideoControllerDurationLabel({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        final remaining = controller.value.duration - value.position;
        return _VideoDurationLabel(duration: remaining);
      },
    );
  }
}

class _VideoDurationLabel extends StatelessWidget {
  const _VideoDurationLabel({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.0.s),
      decoration: BoxDecoration(
        color: context.theme.appColors.backgroundSheet.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6.0.s),
      ),
      child: Text(
        formatDuration(duration),
        style: context.theme.appTextThemes.caption.copyWith(
          color: context.theme.appColors.secondaryBackground,
        ),
      ),
    );
  }
}

class _MuteButton extends StatelessWidget {
  const _MuteButton({
    required this.isMuted,
    required this.onToggle,
  });

  final bool isMuted;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    final icon = isMuted ? Assets.svg.iconChannelMute : Assets.svg.iconChannelUnmute;

    return GestureDetector(
      onTap: () async {
        await onToggle();
      },
      child: Container(
        padding: EdgeInsets.all(6.0.s),
        decoration: BoxDecoration(
          color: context.theme.appColors.backgroundSheet.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12.0.s),
        ),
        child: icon.icon(
          size: 16.0.s,
          color: context.theme.appColors.onPrimaryAccent,
        ),
      ),
    );
  }
}

class _LoadingThumbnail extends StatelessWidget {
  const _LoadingThumbnail({
    required this.url,
    required this.authorPubkey,
  });

  final String url;
  final String authorPubkey;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: _Thumbnail(url: url, authorPubkey: authorPubkey),
          ),
        ),
        const Center(
          child: RepaintBoundary(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.url,
    required this.authorPubkey,
  });

  final String url;
  final String authorPubkey;

  @override
  Widget build(BuildContext context) {
    if (isNetworkUrl(url)) {
      return IonConnectNetworkImage(
        imageUrl: url,
        authorPubkey: authorPubkey,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 100),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    } else {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
      );
    }
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) {
    return VideoButton(
      size: 48.0.s,
      borderRadius: BorderRadius.circular(20.0.s),
      icon: Assets.svg.iconVideoPlay.icon(
        color: context.theme.appColors.secondaryBackground,
        size: 30.0.s,
      ),
    );
  }
}

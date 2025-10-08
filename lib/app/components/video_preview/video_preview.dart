// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/placeholder/ion_placeholder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_network_image/ion_connect_network_image.dart';
import 'package:ion/app/features/core/providers/mute_provider.r.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/settings/providers/video_settings_provider.m.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/hooks/use_route_presence.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoPreview extends HookConsumerWidget {
  const VideoPreview({
    required this.videoUrl,
    required this.authorPubkey,
    this.thumbnailUrl,
    this.onlyOneShouldPlay = true,
    this.framedEventReference,
    this.visibilityThreshold = 1.0,
    super.key,
  });

  final bool onlyOneShouldPlay;
  final String videoUrl;
  final String authorPubkey;
  final String? thumbnailUrl;
  final EventReference? framedEventReference;
  final double visibilityThreshold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uniqueId = useRef(UniqueKey().toString());
    final videoControllerProviderState = ref.watch(
      videoControllerProvider(
        VideoControllerParams(
          sourcePath: videoUrl,
          authorPubkey: authorPubkey,
          looping: true,
          uniqueId: framedEventReference?.encode() ?? '',
          onlyOneShouldPlay: onlyOneShouldPlay,
        ),
      ),
    );
    final videoSettings = ref.watch(videoSettingsProvider);
    final controller = videoControllerProviderState.valueOrNull;

    final isFullyVisible = useState(false);
    final isRouteFocused = useState(true);
    useRoutePresence(
      onBecameInactive: () {
        if (context.mounted) {
          isRouteFocused.value = false;
        }
      },
      onBecameActive: () {
        if (context.mounted) {
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
        if (videoSettings.autoplay && shouldBeActive && !controller.value.isPlaying) {
          controller.play();
        } else if (!shouldBeActive && controller.value.isPlaying) {
          controller.pause();
        }
      },
      [isFullyVisible.value, isRouteFocused.value, controller, videoSettings],
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
            child: ColoredBox(
              color: context.theme.appColors.primaryBackground,
            ),
          ),
          if (thumbnailUrl != null && videoControllerProviderState.isLoading)
            Positioned.fill(
              child: _BlurredThumbnail(
                thumbnailUrl: thumbnailUrl!,
                authorPubkey: authorPubkey,
                isLoading: videoControllerProviderState.isLoading,
              ),
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
          if (hasError)
            const Positioned.fill(
              child: IonPlaceholder(),
            ),
          if (controller != null && controller.value.isInitialized)
            PositionedDirectional(
              bottom: 12.0.s,
              start: 12.0.s,
              end: 12.0.s,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _VideoDurationLabel(controller: controller),
                  _MuteButton(
                    isMuted: isMuted,
                    onToggle: () async {
                      await ref.read(globalMuteNotifierProvider.notifier).toggle();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoDurationLabel extends StatelessWidget {
  const _VideoDurationLabel({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        final remaining = controller.value.duration - value.position;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 4.0.s),
          decoration: BoxDecoration(
            color: context.theme.appColors.backgroundSheet.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6.0.s),
          ),
          child: Text(
            formatDuration(remaining),
            style: context.theme.appTextThemes.caption.copyWith(
              color: context.theme.appColors.secondaryBackground,
            ),
          ),
        );
      },
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

class _BlurredThumbnail extends HookWidget {
  const _BlurredThumbnail({
    required this.thumbnailUrl,
    required this.authorPubkey,
    required this.isLoading,
  });

  final String thumbnailUrl;
  final String authorPubkey;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: IonConnectNetworkImage(
              imageUrl: thumbnailUrl,
              authorPubkey: authorPubkey,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 100),
              fadeOutDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
        if (isLoading)
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

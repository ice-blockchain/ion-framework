// SPDX-License-Identifier: ice License 1.0

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gif/gif.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/image/blurhash_image_wrapper.dart';
import 'package:ion/app/components/placeholder/ion_placeholder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/ion_connect_media_url_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_images_cache_manager.dart';
import 'package:ion/app/features/feed/providers/feed_video_playback_enabled.r.dart';
import 'package:ion/app/features/feed/views/components/feed_network_image/feed_network_image.dart';
import 'package:ion/app/features/settings/providers/video_settings_provider.m.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/hooks/use_route_presence.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// GIF preview widget that pauses animation when not visible on screen
/// or when the feed route is not focused (same behavior as [VideoPreview]).
///
/// Uses [gif] package for explicit playback control via [GifController].
class GifPreview extends HookConsumerWidget {
  const GifPreview({
    required this.imageUrl,
    required this.authorPubkey,
    this.thumbnailUrl,
    this.blurhash,
    this.aspectRatio,
    this.framedEventReference,
    this.visibilityThreshold = 1.0,
    super.key,
  });

  final String imageUrl;
  final String authorPubkey;
  final String? thumbnailUrl;
  final String? blurhash;
  final double? aspectRatio;
  final String? framedEventReference;
  final double visibilityThreshold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uniqueId = useRef(UniqueKey().toString());
    final vsync = useSingleTickerProvider();
    final controller = useMemoized(
      () => GifController(vsync: vsync),
      [vsync],
    );
    useEffect(
      () => controller.dispose,
      [controller],
    );

    final resolvedUrl = ref.watch(ionConnectMediaUrlProvider(imageUrl));
    final gifBytesFuture = useMemoized(
      () => FeedImagesCacheManager.instance
          .getSingleFile(resolvedUrl)
          .then((file) => file.readAsBytes()),
      [resolvedUrl],
    );

    final isVideoPlaybackEnabled = ref.watch(feedVideoPlaybackEnabledNotifierProvider);
    final videoSettings = ref.watch(videoSettingsProvider);
    final isFullyVisible = useState(false);
    final isRouteFocused = useState(true);
    final isGifLoaded = useState(false);

    useRoutePresence(
      onBecameInactive: () {
        if (context.mounted) {
          ref.read(feedVideoPlaybackEnabledNotifierProvider.notifier).disablePlayback();
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

    // On first load, if this is the current route, enable playback right away.
    // Can't use useEffect(init) for this—must run after build.
    useOnInit(
      () {
        if (context.mounted && context.isCurrentRoute) {
          ref.read(feedVideoPlaybackEnabledNotifierProvider.notifier).enablePlayback();
        }
      },
      [],
    );

    final handleVisibilityChanged = useCallback(
      (VisibilityInfo info) {
        if (context.mounted) {
          isFullyVisible.value = info.visibleFraction >= visibilityThreshold;
        }
      },
      [visibilityThreshold],
    );

    final shouldAnimate = isFullyVisible.value &&
        isRouteFocused.value &&
        isVideoPlaybackEnabled &&
        videoSettings.autoplay;

    useOnInit(
      () {
        if (!isGifLoaded.value) return;
        try {
          if (controller.isAnimating) {
            if (!shouldAnimate) {
              controller.stop();
            }
          } else {
            if (shouldAnimate) {
              controller.repeat();
            }
          }
        } catch (_) {
          // GIF may not be ready yet (no Duration) - onFetchCompleted will retry
        }
      },
      [
        isFullyVisible.value,
        isRouteFocused.value,
        isVideoPlaybackEnabled,
        videoSettings.autoplay,
        isGifLoaded.value,
        controller,
      ],
    );

    return VisibilityDetector(
      key: ValueKey(uniqueId),
      onVisibilityChanged: handleVisibilityChanged,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveAspectRatio = aspectRatio ?? constraints.maxWidth / constraints.maxHeight;

          return ColoredBox(
            color: context.theme.appColors.primaryBackground,
            child: FutureBuilder<List<int>>(
              future: gifBytesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _StaticPlaceholder(
                    authorPubkey: authorPubkey,
                    aspectRatio: effectiveAspectRatio,
                    thumbnailUrl: thumbnailUrl,
                    blurhash: blurhash,
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  VisibilityDetectorController.instance.notifyNow();
                });

                return Gif(
                  image: MemoryImage(Uint8List.fromList(snapshot.requireData)),
                  controller: controller,
                  fit: BoxFit.cover,
                  placeholder: (context) => _StaticPlaceholder(
                    authorPubkey: authorPubkey,
                    aspectRatio: effectiveAspectRatio,
                    thumbnailUrl: thumbnailUrl,
                    blurhash: blurhash,
                  ),
                  onFetchCompleted: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!context.mounted) return;
                      isGifLoaded.value = true;
                      try {
                        final settings = ref.read(videoSettingsProvider);
                        final shouldAnimateNow = isFullyVisible.value &&
                            isRouteFocused.value &&
                            ref.read(feedVideoPlaybackEnabledNotifierProvider) &&
                            settings.autoplay;
                        if (controller.isAnimating) {
                          if (!shouldAnimateNow) controller.stop();
                        } else {
                          if (shouldAnimateNow) controller.repeat();
                        }
                      } catch (_) {}
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StaticPlaceholder extends StatelessWidget {
  const _StaticPlaceholder({
    required this.authorPubkey,
    required this.aspectRatio,
    this.thumbnailUrl,
    this.blurhash,
  });

  final String? thumbnailUrl;
  final String authorPubkey;
  final String? blurhash;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final child = (thumbnailUrl ?? '').isNotEmpty
        ? FeedIONConnectNetworkImage(
            imageUrl: thumbnailUrl!,
            authorPubkey: authorPubkey,
            fit: BoxFit.cover,
          )
        : const IonPlaceholder();

    return BlurhashImageWrapper(
      aspectRatio: aspectRatio,
      blurhash: blurhash,
      child: child,
    );
  }
}

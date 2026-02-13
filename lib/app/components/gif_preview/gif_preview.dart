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
    final playbackNotifier = ref.read(feedVideoPlaybackEnabledNotifierProvider.notifier);
    final videoSettings = ref.watch(videoSettingsProvider);
    final isFullyVisible = useState(false);
    final isRouteFocused = useState(true);
    final isGifLoaded = useState(false);

    useRoutePresence(
      onBecameInactive: () {
        if (context.mounted) {
          playbackNotifier.disablePlayback();
          isRouteFocused.value = false;
        }
      },
      onBecameActive: () {
        if (context.mounted) {
          playbackNotifier.enablePlayback();
          isRouteFocused.value = true;
        }
      },
    );

    // On mount, enable playback if already on current route (onBecameActive
    // may not fire for widgets that mount during route transition).
    useOnInit(
      () {
        if (context.mounted && context.isCurrentRoute) {
          playbackNotifier.enablePlayback();
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
          final wouldPlay = isFullyVisible.value && isRouteFocused.value && videoSettings.autoplay;
          // Enable playback when a GIF would play but it's disabled (e.g. full post
          // opened from feed — onBecameActive may not fire during route transition).
          if (wouldPlay && !isVideoPlaybackEnabled) {
            playbackNotifier.enablePlayback();
          }
          if (controller.isAnimating && !shouldAnimate) {
            controller.stop();
          } else if (!controller.isAnimating && shouldAnimate) {
            controller.repeat();
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
      key: ValueKey(uniqueId.value),
      onVisibilityChanged: handleVisibilityChanged,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveAspectRatio = aspectRatio ?? constraints.maxWidth / constraints.maxHeight;

          return ColoredBox(
            color: context.theme.appColors.primaryBackground,
            child: FutureBuilder<List<int>>(
              future: gifBytesFuture,
              builder: (context, snapshot) {
                final placeholder = _StaticPlaceholder(
                  authorPubkey: authorPubkey,
                  aspectRatio: effectiveAspectRatio,
                  thumbnailUrl: thumbnailUrl,
                  blurhash: blurhash,
                );
                if (!snapshot.hasData) return placeholder;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  VisibilityDetectorController.instance.notifyNow();
                });

                return Gif(
                  image: MemoryImage(Uint8List.fromList(snapshot.requireData)),
                  controller: controller,
                  fit: BoxFit.cover,
                  placeholder: (_) => placeholder,
                  onFetchCompleted: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) isGifLoaded.value = true;
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

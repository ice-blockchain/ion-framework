// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/counter_items_footer/counter_items_footer.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/views/components/feed_network_image/feed_network_image.dart';
import 'package:ion/app/features/feed/views/pages/fullscreen_media/hooks/use_image_zoom.dart';
import 'package:ion/app/features/feed/views/pages/fullscreen_media/providers/image_zoom_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/video/views/components/video_actions.dart';
import 'package:ion/app/features/video/views/components/video_post_info.dart';
import 'package:ion/app/features/video/views/pages/video_page.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class MediaCarousel extends HookConsumerWidget {
  const MediaCarousel({
    required this.media,
    required this.initialIndex,
    required this.eventReference,
    required this.entity,
    required this.frameReference,
    super.key,
  });

  final List<MediaAttachment> media;
  final int initialIndex;
  final EventReference eventReference;
  final IonConnectEntity entity;
  final EventReference? frameReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController(initialPage: initialIndex);
    final onPrimaryAccentColor = context.theme.appColors.onPrimaryAccent;

    final currentPage = useState(initialIndex);

    useEffect(
      () {
        void listener() {
          if (pageController.hasClients && pageController.page != null) {
            final newPage = pageController.page!.round();
            if (newPage != currentPage.value) {
              currentPage.value = newPage;
            }
          }
        }

        pageController.addListener(listener);
        return () {
          if (pageController.hasClients) {
            pageController.removeListener(listener);
          }
        };
      },
      [pageController],
    );

    final isZoomed = ref.watch(imageZoomProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: pageController,
          physics: isZoomed ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
          itemCount: media.length,
          itemBuilder: (context, index) {
            final mediaItem = media[index];
            final isVideo = mediaItem.mediaType == MediaType.video;
            if (isVideo) {
              return VideoPage(
                key: ValueKey('video_${mediaItem.url}'),
                videoInfo: VideoPostInfo(videoPost: entity),
                bottomOverlay: VideoActions(
                  eventReference: eventReference,
                  onReplyTap: () => _onReplyTap(context),
                ),
                videoUrl: mediaItem.url,
                authorPubkey: eventReference.masterPubkey,
                thumbnailUrl: mediaItem.thumb,
                blurhash: mediaItem.blurhash,
                aspectRatio: mediaItem.aspectRatio,
                framedEventReference: frameReference,
              );
            }

            return CarouselImageItem(
              key: ValueKey(mediaItem.url),
              imageUrl: mediaItem.url,
              authorPubkey: eventReference.masterPubkey,
              isActive: index == currentPage.value,
            );
          },
        ),
        if (currentPage.value < media.length &&
            media[currentPage.value].mediaType != MediaType.video)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: ColoredBox(
                color: Colors.transparent,
                child: CounterItemsFooter(
                  eventReference: eventReference,
                  color: onPrimaryAccentColor,
                  onReplyTap: () => _onReplyTap(context),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onReplyTap(BuildContext context) {
    if (entity is ModifiablePostEntity || entity is PostEntity) {
      PostDetailsRoute(eventReference: eventReference.encode()).push<void>(context);
    } else if (entity is ArticleEntity) {
      ArticleDetailsRoute(eventReference: eventReference.encode()).push<void>(context);
    }
  }
}

class CarouselImageItem extends HookConsumerWidget {
  const CarouselImageItem({
    required this.imageUrl,
    required this.authorPubkey,
    required this.isActive,
    this.bottomOverlayBuilder,
    super.key,
  });

  final String imageUrl;
  final String authorPubkey;
  final Widget Function(BuildContext)? bottomOverlayBuilder;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomController = useImageZoom(ref, withReset: true);

    useEffect(
      () {
        if (isActive) {
          zoomController.resetZoom?.call();
        }
        return null;
      },
      [isActive],
    );

    final primaryTextColor = context.theme.appColors.primaryText;
    final maxScale = 6.0.s;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: primaryTextColor,
          child: GestureDetector(
            onDoubleTapDown: zoomController.onDoubleTapDown,
            onDoubleTap: zoomController.onDoubleTap,
            child: InteractiveViewer(
              transformationController: zoomController.transformationController,
              maxScale: maxScale,
              clipBehavior: Clip.none,
              onInteractionStart: zoomController.onInteractionStart,
              onInteractionUpdate: zoomController.onInteractionUpdate,
              onInteractionEnd: zoomController.onInteractionEnd,
              child: FeedIONConnectNetworkImage(
                imageUrl: imageUrl,
                authorPubkey: authorPubkey,
                placeholder: (_, __) => const CenteredLoadingIndicator(),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        if (bottomOverlayBuilder != null)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: bottomOverlayBuilder!(context),
          ),
      ],
    );
  }
}

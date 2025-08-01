// SPDX-License-Identifier: ice License 1.0
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/counter_items_footer/counter_items_footer.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/components/feed_network_image/feed_network_image.dart';
import 'package:ion/app/features/feed/views/pages/fullscreen_media/hooks/use_image_zoom.dart';
import 'package:ion/app/features/feed/views/pages/fullscreen_media/providers/image_zoom_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';

class ImageCarousel extends HookConsumerWidget {
  const ImageCarousel({
    required this.images,
    required this.initialIndex,
    required this.eventReference,
    super.key,
  });

  final List<MediaAttachment> images;
  final int initialIndex;
  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController(initialPage: initialIndex);
    final onPrimaryAccentColor = context.theme.appColors.onPrimaryAccent;

    final zoomController = useImageZoom(ref, withReset: true);
    final currentPage = useState(initialIndex);

    useEffect(
      () {
        void listener() {
          if (pageController.hasClients && pageController.page != null) {
            final newPage = pageController.page!.round();
            if (newPage != currentPage.value) {
              currentPage.value = newPage;
              zoomController.resetZoom?.call();
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
      [pageController, zoomController],
    );

    final isZoomed = ref.watch(imageZoomProvider);

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: pageController,
            physics: isZoomed ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return CarouselImageItem(
                key: ValueKey(images[index].url),
                imageUrl: images[index].url,
                authorPubkey: eventReference.masterPubkey,
                zoomController: zoomController,
                bottomOverlayBuilder: index == currentPage.value
                    ? (context) => SafeArea(
                          top: false,
                          child: ColoredBox(
                            color: Colors.transparent,
                            child: CounterItemsFooter(
                              eventReference: eventReference,
                              color: onPrimaryAccentColor,
                            ),
                          ),
                        )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class CarouselImageItem extends StatelessWidget {
  const CarouselImageItem({
    required this.imageUrl,
    required this.authorPubkey,
    required this.zoomController,
    this.bottomOverlayBuilder,
    super.key,
  });

  final String imageUrl;
  final String authorPubkey;
  final ImageZoomController zoomController;
  final Widget Function(BuildContext)? bottomOverlayBuilder;

  @override
  Widget build(BuildContext context) {
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

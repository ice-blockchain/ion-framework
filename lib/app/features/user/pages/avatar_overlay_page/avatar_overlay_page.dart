// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/components/ion_connect_network_image/ion_connect_network_image.dart';
import 'package:ion/app/features/feed/views/pages/fullscreen_media/hooks/use_image_zoom.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';

class AvatarOverlayPage extends HookConsumerWidget {
  const AvatarOverlayPage({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pictureUrl = ref.watch(
      userMetadataProvider(pubkey).select((state) => state.valueOrNull?.data.picture),
    );

    final zoomController = useImageZoom(ref);

    return ColoredBox(
      color: context.theme.appColors.backgroundSheet.withAlpha(179),
      child: _ImageHitTestWidget(
        onTapOutside: context.pop,
        child: GestureDetector(
          onDoubleTapDown: zoomController.onDoubleTapDown,
          onDoubleTap: zoomController.onDoubleTap,
          child: InteractiveViewer(
            transformationController: zoomController.transformationController,
            maxScale: 6.0.s,
            clipBehavior: Clip.none,
            onInteractionStart: zoomController.onInteractionStart,
            onInteractionUpdate: zoomController.onInteractionUpdate,
            onInteractionEnd: zoomController.onInteractionEnd,
            child: pictureUrl != null
                ? SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: IonConnectNetworkImage(
                      imageUrl: pictureUrl,
                      authorPubkey: pubkey,
                      fit: BoxFit.fitWidth,
                      errorWidget: (context, error, stackTrace) {
                        return _FallbackAvatar(
                          pubkey: pubkey,
                        );
                      },
                    ),
                  )
                : _FallbackAvatar(pubkey: pubkey),
          ),
        ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({
    required this.pubkey,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context) {
    return IonConnectAvatar(
      size: MediaQuery.of(context).size.width,
      masterPubkey: pubkey,
      fit: BoxFit.fitWidth,
    );
  }
}

class _ImageHitTestWidget extends StatelessWidget {
  const _ImageHitTestWidget({
    required this.child,
    required this.onTapOutside,
  });

  final Widget child;
  final VoidCallback onTapOutside;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        // Calculate image bounds
        final screenSize = MediaQuery.of(context).size;
        final imageWidth = screenSize.width;
        final imageHeight = imageWidth;

        final imageBounds = Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2),
          width: imageWidth,
          height: imageHeight,
        );

        // Check if tap is outside image bounds
        if (!imageBounds.contains(event.localPosition)) {
          onTapOutside();
        }
      },
      child: child,
    );
  }
}

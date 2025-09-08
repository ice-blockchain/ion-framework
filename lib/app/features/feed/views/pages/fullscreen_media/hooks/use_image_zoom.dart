// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/views/pages/fullscreen_media/providers/image_zoom_provider.r.dart';
import 'package:ion/app/utils/future.dart';

class ImageZoomController {
  const ImageZoomController({
    required this.transformationController,
    required this.onDoubleTapDown,
    required this.onDoubleTap,
    required this.onInteractionStart,
    required this.onInteractionUpdate,
    required this.onInteractionEnd,
    this.resetZoom,
  });

  final TransformationController transformationController;
  final void Function(TapDownDetails details) onDoubleTapDown;
  final VoidCallback onDoubleTap;
  final void Function(ScaleStartDetails details) onInteractionStart;
  final void Function(ScaleUpdateDetails details) onInteractionUpdate;
  final void Function(ScaleEndDetails details) onInteractionEnd;
  final VoidCallback? resetZoom;
}

ImageZoomController useImageZoom(WidgetRef ref, {bool withReset = false}) {
  final transformationController = useTransformationController();
  final animationController = useAnimationController(duration: 300.ms);
  final zoomNotifier = ref.watch(imageZoomProvider.notifier);
  final tapDownDetails = useState<TapDownDetails?>(null);
  final matrixAnimation = useState<Animation<Matrix4>?>(null);
  final context = useContext();
  final mounted = context.mounted;

  final hasZoomedDuringGesture = useRef<bool>(false);

  useEffect(() {
    void animationListener() {
      final anim = matrixAnimation.value;
      if (anim == null) return;
      transformationController.value = anim.value;
    }

    void animationStatusListener(AnimationStatus status) {
      if (!mounted) return;
      if (status == AnimationStatus.completed) {
        final currentlyZoomed = transformationController.value != Matrix4.identity();

        final alreadyZoomed = ref.read(imageZoomProvider);
        if (alreadyZoomed != currentlyZoomed) {
          zoomNotifier.zoomed = currentlyZoomed;

          if (!currentlyZoomed && alreadyZoomed) {
            HapticFeedback.lightImpact();
          }
        }
      }
    }

    animationController
      ..addListener(animationListener)
      ..addStatusListener(animationStatusListener);

    return () {
      animationController
        ..removeListener(animationListener)
        ..removeStatusListener(animationStatusListener);
    };
  }, [
    animationController,
    matrixAnimation.value,
    transformationController,
    mounted,
  ]);

  void handleDoubleTap() {
    final details = tapDownDetails.value;
    if (details == null) return;

    final currentZoomState = ref.read(imageZoomProvider);
    final newZoomState = !currentZoomState;
    final position = details.localPosition;

    final endMatrix = newZoomState
        ? (Matrix4.identity()
          ..translateByDouble(-position.dx * 2, -position.dy * 2, 0, 1)
          ..scaleByDouble(3, 3, 1, 1))
        : Matrix4.identity();

    matrixAnimation.value = Matrix4Tween(
      begin: transformationController.value,
      end: endMatrix,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      ),
    );

    animationController
      ..reset()
      ..forward();
  }

  void handleInteractionStart(ScaleStartDetails details) {
    if (animationController.isAnimating) {
      animationController.stop();
    }

    hasZoomedDuringGesture.value = false;
  }

  void handleInteractionUpdate(ScaleUpdateDetails details) {
    final scale = transformationController.value.getMaxScaleOnAxis();
    if (scale > 1.01) {
      hasZoomedDuringGesture.value = true;
    }
  }

  void handleInteractionEnd(ScaleEndDetails details) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scale = transformationController.value.getMaxScaleOnAxis();
      final isZoomed = (scale - 1.0).abs() > 0.01;

      if (hasZoomedDuringGesture.value && !isZoomed) {
        HapticFeedback.lightImpact();
      }

      final currentZoomState = ref.read(imageZoomProvider);
      if (currentZoomState != isZoomed) {
        zoomNotifier.zoomed = isZoomed;
      }
    });
  }

  VoidCallback? resetZoomCallback;
  if (withReset) {
    resetZoomCallback = () {
      if (animationController.isAnimating) {
        animationController.stop();
      }
      if (transformationController.value != Matrix4.identity()) {
        matrixAnimation.value = Matrix4Tween(
          begin: transformationController.value,
          end: Matrix4.identity(),
        ).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Curves.easeOut,
          ),
        );
        animationController
          ..reset()
          ..forward();
        if (ref.read(imageZoomProvider)) {
          zoomNotifier.zoomed = false;
        }
      }
    };
  }

  return ImageZoomController(
    transformationController: transformationController,
    onDoubleTapDown: (details) => tapDownDetails.value = details,
    onDoubleTap: handleDoubleTap,
    onInteractionStart: handleInteractionStart,
    onInteractionUpdate: handleInteractionUpdate,
    onInteractionEnd: handleInteractionEnd,
    resetZoom: resetZoomCallback,
  );
}

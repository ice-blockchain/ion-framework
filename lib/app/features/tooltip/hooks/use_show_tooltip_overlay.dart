// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/features/tooltip/views/tooltip.dart';
import 'package:ion/app/hooks/use_route_presence.dart';

VoidCallback useShowTooltipOverlay({
  required GlobalKey targetKey,
  required String text,
  Duration animationDuration = const Duration(milliseconds: 150),
  Duration autoDismissDuration = const Duration(milliseconds: 1500),
  TooltipPointerPosition pointerPosition = TooltipPointerPosition.topCenter,
  TooltipPosition position = TooltipPosition.top,
  double horizontalPadding = 32.0,
}) {
  final overlayEntry = useRef<OverlayEntry?>(null);
  final dismissTimer = useRef<Timer?>(null);
  final animationController = useAnimationController(duration: animationDuration);

  final opacityAnimation = useMemoized(
    () => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animationController, curve: Curves.fastOutSlowIn),
    ),
    [animationController],
  );

  final scaleAnimation = useMemoized(
    () => Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: animationController, curve: Curves.fastOutSlowIn),
    ),
    [animationController],
  );

  // Cleanup function to hide and remove overlay
  void hideOverlay() {
    dismissTimer.value?.cancel();
    dismissTimer.value = null;

    if (overlayEntry.value != null) {
      animationController.reverse().then((_) {
        overlayEntry.value?.remove();
        overlayEntry.value = null;
      });
    }
  }

  // Cleanup on widget disposal
  useEffect(
    () {
      return hideOverlay;
    },
    [],
  );

  // Hide overlay when route becomes inactive (navigation occurs)
  useRoutePresence(
    onBecameInactive: hideOverlay,
  );

  return useCallback(
    () {
      if (overlayEntry.value != null) return;

      final context = targetKey.currentContext;
      if (context == null) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final targetRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;

      overlayEntry.value = OverlayEntry(
        builder: (context) {
          return Positioned.fill(
            child: CustomSingleChildLayout(
              delegate: _TooltipLayoutDelegate(
                targetRect,
                position: position,
              ),
              child: TooltipOverlay(
                text: text,
                opacityAnimation: opacityAnimation,
                scaleAnimation: scaleAnimation,
                targetRect: targetRect,
                pointerPosition: pointerPosition,
                position: position,
                horizontalPadding: horizontalPadding,
              ),
            ),
          );
        },
      );

      Overlay.of(context).insert(overlayEntry.value!);
      animationController.forward();

      dismissTimer.value = Timer(autoDismissDuration, () async {
        await animationController.reverse();
        overlayEntry.value?.remove();
        overlayEntry.value = null;
        dismissTimer.value = null;
      });
    },
    [
      targetKey,
      opacityAnimation,
      scaleAnimation,
      animationController,
      pointerPosition,
      position,
      horizontalPadding,
    ],
  );
}

class _TooltipLayoutDelegate extends SingleChildLayoutDelegate {
  _TooltipLayoutDelegate(
    this.targetRect, {
    required this.position,
  });

  final Rect targetRect;
  final TooltipPosition position;
  static const double _screenPadding = 8;
  static const double _tooltipGap = 8;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // Calculate the maximum available width considering screen padding
    final availableWidth = constraints.maxWidth - (_screenPadding * 2);

    return BoxConstraints(
      maxWidth: availableWidth,
      maxHeight: constraints.maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final targetCenter = targetRect.center;

    var dx = targetCenter.dx - childSize.width / 2;
    if (dx < _screenPadding) {
      dx = _screenPadding;
    } else if (dx + childSize.width > size.width - _screenPadding) {
      dx = size.width - childSize.width - _screenPadding;
    }

    double dy;
    if (position == TooltipPosition.top) {
      dy = targetRect.top - childSize.height - _tooltipGap;
    } else {
      dy = targetRect.bottom + _tooltipGap;
    }

    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_TooltipLayoutDelegate oldDelegate) =>
      targetRect != oldDelegate.targetRect || position != oldDelegate.position;
}

// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/features/wallets/views/pages/nft_details/components/unavailable_tooltip.dart';

VoidCallback useShowTooltipOverlay({
  required GlobalKey targetKey,
  required String text,
  Duration animationDuration = const Duration(milliseconds: 150),
  Duration autoDismissDuration = const Duration(milliseconds: 1500),
}) {
  final overlayEntry = useRef<OverlayEntry?>(null);
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
              delegate: _TooltipLayoutDelegate(targetRect),
              child: UnavailableTooltipOverlay(
                text: text,
                opacityAnimation: opacityAnimation,
                scaleAnimation: scaleAnimation,
                targetRect: targetRect,
              ),
            ),
          );
        },
      );

      Overlay.of(context).insert(overlayEntry.value!);
      animationController.forward();

      Future.delayed(autoDismissDuration, () async {
        await animationController.reverse();
        overlayEntry.value?.remove();
        overlayEntry.value = null;
      });
    },
    [targetKey, opacityAnimation, scaleAnimation, animationController],
  );
}

class _TooltipLayoutDelegate extends SingleChildLayoutDelegate {
  _TooltipLayoutDelegate(this.targetRect);

  final Rect targetRect;
  static const double _screenPadding = 8;
  static const double _tooltipGap = 8;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final targetCenter = targetRect.center;

    var dx = targetCenter.dx - childSize.width / 2;
    if (dx < _screenPadding) {
      dx = _screenPadding;
    } else if (dx + childSize.width > size.width - _screenPadding) {
      dx = size.width - childSize.width - _screenPadding;
    }

    final dy = targetRect.top - childSize.height - _tooltipGap;

    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_TooltipLayoutDelegate oldDelegate) => targetRect != oldDelegate.targetRect;
}

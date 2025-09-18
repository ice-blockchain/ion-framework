// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/views/pages/nft_details/components/unavailable_nft_tooltip.dart';

VoidCallback useShowTooltipOverlay({
  required GlobalKey targetKey,
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

      final offset = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final overlayHeight = 51.s;
      final topPosition = offset.dy - size.height - overlayHeight;

      overlayEntry.value = OverlayEntry(
        builder: (context) {
          return PositionedDirectional(
            width: MediaQuery.sizeOf(context).width,
            top: topPosition,
            height: overlayHeight,
            child: UnavailableNftTooltipOverlay(
              opacityAnimation: opacityAnimation,
              scaleAnimation: scaleAnimation,
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

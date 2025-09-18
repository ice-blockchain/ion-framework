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
  // Tooltip sizing constants
  final triangleHeight = 10.0.s;
  final tooltipMaxWidth = 300.0.s;
  final contentPadding = EdgeInsets.symmetric(horizontal: 32.s, vertical: 11.s);
  final textMaxWidth = tooltipMaxWidth - contentPadding.horizontal;

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

      final message = context.i18n.send_nft_sending_nft_will_be_available_later;
      final tooltip = UnavailableNftTooltipOverlay(
        message: message,
        maxWidth: tooltipMaxWidth,
        scaleAnimation: scaleAnimation,
        triangleHeight: triangleHeight,
        contentPadding: contentPadding,
        opacityAnimation: opacityAnimation,
      );

      // Calculate the tooltip height inline
      final textStyle = context.theme.appTextThemes.body2.copyWith(
        color: context.theme.appColors.secondaryText,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: message, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: textMaxWidth);

      final textHeight = textPainter.height;
      final overlayHeight = textHeight + contentPadding.vertical + triangleHeight;
      textPainter.dispose();

      final topPosition = offset.dy - size.height - overlayHeight;
      overlayEntry.value = OverlayEntry(
        builder: (context) {
          return PositionedDirectional(
            width: MediaQuery.sizeOf(context).width,
            top: topPosition,
            child: tooltip,
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

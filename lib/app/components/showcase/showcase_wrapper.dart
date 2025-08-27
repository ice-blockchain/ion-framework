// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:showcaseview/showcaseview.dart';

class ShowcaseWrapper extends StatelessWidget {
  const ShowcaseWrapper({
    required this.child,
    required this.tooltipBuilder,
    required this.showcaseKey,
    required this.tooltipWidth,
    this.isUpArrow = true,
    this.targetBorderRadius = BorderRadius.zero,
    this.onTap,
    this.onDismissed,
    super.key,
  });

  final Widget child;
  final Widget Function(BuildContext context, Widget arrow) tooltipBuilder;
  final GlobalKey showcaseKey;
  final double tooltipWidth;
  final bool isUpArrow;
  final BorderRadius targetBorderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context) {
    return Showcase.withWidget(
      key: showcaseKey,
      targetBorderRadius: targetBorderRadius,
      overlayColor: context.theme.appColors.backgroundSheet,
      height: null,
      width: tooltipWidth,
      onTargetClick: () => _onTapped(context),
      onBarrierClick: () => _onDismissed(context),
      disposeOnTap: true,
      container: tooltipBuilder(
        context,
        CustomPaint(
          painter: _Arrow(
            strokeColor: context.theme.appColors.primaryBackground,
            isUpArrow: isUpArrow,
          ),
          child: SizedBox(
            height: 7.5.s,
            width: 19.s,
          ),
        ),
      ),
      child: child,
    );
  }

  void _onTapped(BuildContext context) {
    ShowCaseWidget.of(context).dismiss();
    (onTap ?? onDismissed)?.call();
  }

  void _onDismissed(BuildContext context) {
    ShowCaseWidget.of(context).dismiss();
    onDismissed?.call();
  }
}

class _Arrow extends CustomPainter {
  _Arrow({
    this.strokeColor = Colors.black,
    this.isUpArrow = true,
  }) : _paint = Paint()
          ..color = strokeColor
          ..strokeWidth = 3
          ..style = PaintingStyle.fill;

  final Color strokeColor;
  final bool isUpArrow;
  final Paint _paint;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(getTrianglePath(size.width, size.height), _paint);
  }

  Path getTrianglePath(double x, double y) {
    if (isUpArrow) {
      return Path()
        ..moveTo(0, y)
        ..lineTo(x / 2, 0)
        ..lineTo(x, y)
        ..lineTo(0, y);
    }
    return Path()
      ..moveTo(0, 0)
      ..lineTo(x, 0)
      ..lineTo(x / 2, y)
      ..lineTo(0, 0);
  }

  @override
  bool shouldRepaint(covariant _Arrow oldDelegate) {
    return oldDelegate.strokeColor != strokeColor;
  }
}

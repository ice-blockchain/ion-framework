// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/shapes/shape.dart';
import 'package:ion/app/components/shapes/triangle_path.dart';
import 'package:ion/app/extensions/extensions.dart';

enum TooltipPointerPosition {
  topCenter,
  topLeft,
  topRight,
  bottomCenter,
  bottomLeft,
  bottomRight,
}

enum TooltipPosition {
  top,
  bottom,
}

class TooltipOverlay extends StatelessWidget {
  const TooltipOverlay({
    required this.opacityAnimation,
    required this.scaleAnimation,
    required this.targetRect,
    required this.text,
    required this.pointerPosition,
    required this.position,
    this.horizontalPadding = 32.0,
    super.key,
  });

  final Animation<double> opacityAnimation;
  final Animation<double> scaleAnimation;
  final Rect targetRect;
  final String text;
  final TooltipPointerPosition pointerPosition;
  final TooltipPosition position;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([opacityAnimation, scaleAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: opacityAnimation.value,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tooltipRenderBox = context.findRenderObject() as RenderBox?;
                  if (tooltipRenderBox == null) return const SizedBox.shrink();

                  final tooltipWidth = tooltipRenderBox.size.width;
                  final tooltipDx = tooltipRenderBox.localToGlobal(Offset.zero).dx;
                  final targetCenterDx = targetRect.center.dx;

                  const pointerWidth = 12;
                  final sideOffset = 25.s;

                  double calculatedPointerPosition;
                  switch (pointerPosition) {
                    case TooltipPointerPosition.topCenter:
                    case TooltipPointerPosition.bottomCenter:
                      calculatedPointerPosition = targetCenterDx - tooltipDx;
                    case TooltipPointerPosition.topLeft:
                    case TooltipPointerPosition.bottomLeft:
                      calculatedPointerPosition = sideOffset;
                    case TooltipPointerPosition.topRight:
                    case TooltipPointerPosition.bottomRight:
                      calculatedPointerPosition = tooltipWidth - sideOffset;
                  }

                  // Clamp the pointer position to be within the tooltip bounds
                  final clampedPointerPosition = calculatedPointerPosition.clamp(
                    pointerWidth / 2,
                    tooltipWidth - pointerWidth / 2,
                  );

                  final isArrowAtTop = pointerPosition == TooltipPointerPosition.topCenter ||
                      pointerPosition == TooltipPointerPosition.topLeft ||
                      pointerPosition == TooltipPointerPosition.topRight;
                  final isArrowAtBottom = pointerPosition == TooltipPointerPosition.bottomCenter ||
                      pointerPosition == TooltipPointerPosition.bottomLeft ||
                      pointerPosition == TooltipPointerPosition.bottomRight;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: EdgeInsetsDirectional.only(
                          top: isArrowAtTop ? 10.s : 0,
                          bottom: isArrowAtBottom ? 10.s : 0,
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: horizontalPadding.s, vertical: 11.s),
                        decoration: BoxDecoration(
                          color: context.theme.appColors.onPrimaryAccent,
                          borderRadius: BorderRadius.circular(16.0.s),
                          boxShadow: [
                            BoxShadow(
                              color: context.theme.appColors.primaryText.withValues(alpha: 0.08),
                              blurRadius: 16.0.s,
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                        child: Text(
                          text,
                          style: context.theme.appTextThemes.body2.copyWith(
                            color: context.theme.appColors.secondaryText,
                          ),
                        ),
                      ),
                      if (isArrowAtTop)
                        PositionedDirectional(
                          top: 0,
                          start: clampedPointerPosition - (pointerWidth / 2),
                          child: Transform.rotate(
                            angle: 3.14159, // 180 degrees
                            child: _TrianglePointer(
                              color: context.theme.appColors.onPrimaryAccent,
                              height: 10.s,
                            ),
                          ),
                        ),
                      if (isArrowAtBottom)
                        PositionedDirectional(
                          bottom: 0,
                          start: clampedPointerPosition - (pointerWidth / 2),
                          child: _TrianglePointer(
                            color: context.theme.appColors.onPrimaryAccent,
                            height: 10.s,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrianglePointer extends StatelessWidget {
  const _TrianglePointer({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(12.s, height),
      painter: ShapePainter(
        const TriangleShapeBuilder(),
        color: color,
      ),
    );
  }
}

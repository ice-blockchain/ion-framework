// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/shapes/shape.dart';
import 'package:ion/app/components/shapes/triangle_path.dart';
import 'package:ion/app/extensions/extensions.dart';

class UnavailableTooltipOverlay extends StatelessWidget {
  const UnavailableTooltipOverlay({
    required this.opacityAnimation,
    required this.scaleAnimation,
    required this.targetRect,
    required this.text,
    super.key,
  });

  final Animation<double> opacityAnimation;
  final Animation<double> scaleAnimation;
  final Rect targetRect;
  final String text;

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
                  final tooltipWidth = constraints.maxWidth;
                  final targetCenterDx = targetRect.center.dx;

                  final tooltipRenderBox = context.findRenderObject() as RenderBox?;
                  if (tooltipRenderBox == null) return const SizedBox.shrink();

                  final tooltipDx = tooltipRenderBox.localToGlobal(Offset.zero).dx;

                  final pointerPositionInTooltip = targetCenterDx - tooltipDx;

                  // Clamp the pointer position to be within the tooltip bounds
                  const pointerWidth = 12;
                  final clampedPointerPosition = pointerPositionInTooltip.clamp(
                    pointerWidth / 2,
                    tooltipWidth - pointerWidth / 2,
                  );

                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.symmetric(horizontal: 32.s, vertical: 11.s),
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
                        constraints: BoxConstraints(maxWidth: 300.s),
                        child: Text(
                          text,
                          style: context.theme.appTextThemes.body2.copyWith(
                            color: context.theme.appColors.secondaryText,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: clampedPointerPosition - (pointerWidth / 2),
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

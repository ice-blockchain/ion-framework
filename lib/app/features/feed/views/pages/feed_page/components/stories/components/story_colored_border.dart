// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:ion/app/components/shapes/hexagon_path.dart';
import 'package:ion/app/components/shapes/shape.dart';
import 'package:ion/app/extensions/extensions.dart';

class StoryColoredBorderWrapper extends StatelessWidget {
  const StoryColoredBorderWrapper({
    required this.size,
    super.key,
    this.hexagon = false,
    this.color,
    this.gradient,
    this.isViewed = false,
    this.borderRadius,
    this.child,
  });

  final double size;

  final bool hexagon;

  final Color? color;

  final Gradient? gradient;

  final bool isViewed;

  final BorderRadiusGeometry? borderRadius;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isViewed ? context.theme.appColors.sheetLine : color;
    final effectiveGradient = isViewed ? null : gradient;

    return SizedBox.square(
      dimension: size,
      child: hexagon
          ? CustomPaint(
              size: Size.square(size),
              painter: ShapePainter(
                HexagonShapeBuilder(),
                color: effectiveColor,
                shader: effectiveGradient?.createShader(
                  Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2),
                ),
              ),
              child: Center(child: child),
            )
          : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: borderRadius?.add(BorderRadiusGeometry.circular(4.s)) ??
                    BorderRadius.circular(size * 0.3),
                border: effectiveGradient == null
                    ? GradientBoxBorder(
                        gradient: LinearGradient(colors: [effectiveColor!, effectiveColor]),
                        width: 2.s,
                      )
                    : GradientBoxBorder(gradient: effectiveGradient, width: 2.s),
              ),
              child: Center(child: child),
            ),
    );
  }
}

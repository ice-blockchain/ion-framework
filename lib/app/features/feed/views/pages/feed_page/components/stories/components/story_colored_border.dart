// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/avatar/avatar_constants.dart';
import 'package:ion/app/components/shapes/hexagon_path.dart';
import 'package:ion/app/components/shapes/shape.dart';
import 'package:ion/app/extensions/extensions.dart';

class StoryColoredBorder extends StatelessWidget {
  const StoryColoredBorder({
    required this.size,
    super.key,
    this.hexagon = false,
    this.color,
    this.gradient,
    this.isViewed = false,
    this.child,
  });

  final double size;

  final bool hexagon;

  final Color? color;

  final Gradient? gradient;

  final bool isViewed;

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
                gradient: effectiveGradient,
                borderRadius: BorderRadius.circular(size * AvatarConstants.borderRadiusRatio),
                color: effectiveColor,
              ),
              child: Center(child: child),
            ),
    );
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class GradientHorizontalDivider extends StatelessWidget {
  const GradientHorizontalDivider({
    this.margin,
    this.height = 0.5,
    this.colors,
    super.key,
  });

  final EdgeInsetsGeometry? margin;
  final double height;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final defaultColor = context.theme.appColors.onTertiaryFill;

    return Container(
      margin: margin,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          stops: const [0.0529, 0.5, 0.9471],
          colors: colors ??
              [
                defaultColor.withValues(alpha: 0),
                defaultColor,
                defaultColor.withValues(alpha: 0),
              ],
        ),
      ),
    );
  }
}

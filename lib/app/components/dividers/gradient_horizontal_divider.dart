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
    return Container(
      margin: margin,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          stops: const [0, 0.25, 0.5, 0.75, 1.0], // Adjusted stops to make the middle section wider
          colors: colors ??
              [
                Colors.transparent,
                context.theme.appColors.onTertiaryFill,
                context.theme.appColors.onTertiaryFill,
                context.theme.appColors.onTertiaryFill,
                Colors.transparent,
              ],
        ),
      ),
    );
  }
}

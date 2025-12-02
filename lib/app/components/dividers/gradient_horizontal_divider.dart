// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

class GradientHorizontalDivider extends StatelessWidget {
  const GradientHorizontalDivider({
    this.margin,
    this.height = 0.5,
    this.colors = const [Color(0x00ffffff), Color(0xffe1eaf8), Color(0x00ffffff)],
    super.key,
  });

  final EdgeInsetsGeometry? margin;
  final double height;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
        ),
      ),
    );
  }
}

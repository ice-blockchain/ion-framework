// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';

class SectionSeparator extends StatelessWidget {
  const SectionSeparator({
    super.key,
    this.color,
    this.height,
  });

  final double? height;
  final Color? color;

  static double defaultHeight = 4.0.s;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color ?? context.theme.appColors.primaryBackground,
      child: ConstrainedBox(
        constraints: BoxConstraints.tight(
          Size.fromHeight(height ?? defaultHeight),
        ),
      ),
    );
  }
}

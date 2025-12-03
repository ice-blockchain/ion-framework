// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class HorizontalSeparator extends StatelessWidget {
  const HorizontalSeparator({
    super.key,
    this.height = 0.5,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      child: Container(
        height: 0.5.s,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.theme.appColors.secondaryBackground,
              context.theme.appColors.onTertiaryFill,
              context.theme.appColors.secondaryBackground,
            ],
            stops: const [
              0.0,
              0.5,
              1.0,
            ],
          ),
        ),
      ),
    );
  }
}

class SimpleSeparator extends StatelessWidget {
  const SimpleSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 4.s,
      thickness: 4.s,
      color: context.theme.appColors.onSecondaryBackground,
    );
  }
}

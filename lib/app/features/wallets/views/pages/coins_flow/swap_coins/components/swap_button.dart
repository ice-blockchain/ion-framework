// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class SwapButton extends StatelessWidget {
  const SwapButton({
    required this.onTap,
    super.key,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0.s),
        child: Center(
          child: Container(
            width: 34.0.s,
            height: 34.0.s,
            decoration: BoxDecoration(
              color: colors.tertiaryBackground,
              borderRadius: BorderRadius.circular(12.0.s),
              border: Border.all(
                color: colors.secondaryBackground,
                width: 3,
              ),
            ),
            child: Center(
              child: Assets.svg.iconamoonSwap.icon(
                color: colors.primaryText,
                size: 24.0.s,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

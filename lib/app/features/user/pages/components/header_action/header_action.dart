// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';

class HeaderAction extends StatelessWidget {
  const HeaderAction({
    required this.onPressed,
    required this.assetName,
    this.disabled = false,
    this.loading = false,
    this.opacity = 0,
    this.flipForRtl = false,
    this.backgroundColor,
    this.iconColor,
    super.key,
  });

  final String assetName;
  final VoidCallback onPressed;
  final bool disabled;
  final bool loading;
  final double opacity;
  final bool flipForRtl;
  final Color? backgroundColor;
  final Color? iconColor;

  static double get buttonSize => 60.0.s;

  double get iconSize => 24.0.s;

  @override
  Widget build(BuildContext context) {
    final interpolatedButtonSize = lerpDouble(buttonSize, iconSize, opacity)!;
    final backgroundColor = this.backgroundColor ??
        Color.lerp(
          context.theme.appColors.tertiaryBackground,
          context.theme.appColors.secondaryBackground,
          opacity,
        )!;
    final borderColor = this.backgroundColor ??
        Color.lerp(
          context.theme.appColors.onTertiaryFill,
          context.theme.appColors.secondaryBackground,
          opacity,
        )!;

    return Button.icon(
      disabled: disabled,
      size: interpolatedButtonSize,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      tintColor: iconColor ?? context.theme.appColors.primaryText,
      icon: loading
          ? const IONLoadingIndicator(type: IndicatorType.dark)
          : assetName.icon(
              size: iconSize,
              color: iconColor ?? context.theme.appColors.primaryText,
              flipForRtl: flipForRtl,
            ),
      onPressed: onPressed,
    );
  }
}

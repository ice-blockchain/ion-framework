// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/shadow/svg_shadow.dart';
import 'package:ion/app/constants/ui.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/services/keyboard/keyboard.dart';
import 'package:ion/generated/assets.gen.dart';

class NavigationBackButton extends StatelessWidget {
  const NavigationBackButton(
    this.onPress, {
    super.key,
    this.hideKeyboardOnBack = false,
    this.icon,
    this.color,
    this.showShadow = false,
  });

  final VoidCallback onPress;

  final bool hideKeyboardOnBack;

  final Color? color;

  final Widget? icon;

  final bool showShadow;

  static double get iconSize => 24.0.s;

  static double get totalSize => iconSize + UiConstants.hitSlop * 4;

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = icon ??
        Assets.svg.iconBackArrow.icon(
          color: color,
          size: iconSize,
          flipForRtl: true,
        );

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () => hideKeyboardOnBack ? hideKeyboard(context, callback: onPress) : onPress(),
        icon: showShadow ? SvgShadow(child: effectiveIcon) : effectiveIcon,
      ),
    );
  }
}

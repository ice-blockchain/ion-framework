// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/shadow/svg_shadow.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_icon_button.dart';
import 'package:ion/app/services/keyboard/keyboard.dart';
import 'package:ion/generated/assets.gen.dart';

class NavigationBackButton extends StatelessWidget {
  const NavigationBackButton(
    this.onPress, {
    super.key,
    this.hideKeyboardOnBack = false,
    this.icon,
    this.showShadow = false,
  });

  final VoidCallback onPress;

  final bool hideKeyboardOnBack;

  final Widget? icon;

  final bool showShadow;

  static double get iconSize => NavigationIconButton.iconSize;

  static double get totalSize => NavigationIconButton.totalSize;

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = icon ??
        Assets.svg.iconBackArrow.icon(
          size: iconSize,
          flipForRtl: true,
        );

    final iconWidget = showShadow ? SvgShadow(child: effectiveIcon) : effectiveIcon;

    return NavigationIconButton(
      onPress: () => hideKeyboardOnBack ? hideKeyboard(context, callback: onPress) : onPress(),
      icon: iconWidget,
    );
  }
}

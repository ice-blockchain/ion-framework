// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/constants/ui.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class NavigationCloseButton extends StatelessWidget {
  const NavigationCloseButton({
    super.key,
    this.onPressed,
    this.color,
  });

  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed ?? Navigator.of(context, rootNavigator: true).pop,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: UiConstants.hitSlop,
          vertical: UiConstants.hitSlop * 2,
        ),
        child: Assets.svg.iconSheetClose.icon(
          color: color ?? context.theme.appColors.tertiaryText,
        ),
      ),
    );
  }
}

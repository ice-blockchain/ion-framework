// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/constants/ui.dart';
import 'package:ion/app/extensions/num.dart';

class NavigationIconButton extends StatelessWidget {
  const NavigationIconButton({
    required this.onPress,
    required this.icon,
    super.key,
  });

  final VoidCallback onPress;
  final Widget icon;

  static double get iconSize => 24.0.s;

  static double get totalSize => iconSize + UiConstants.hitSlop * 4;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPress,
        icon: icon,
      ),
    );
  }
}

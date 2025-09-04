// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class TabIcon extends StatelessWidget {
  const TabIcon({
    required this.icon,
    required this.isSelected,
    super.key,
  });

  final String icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.0.s,
      child: icon.icon(
        size: 24.0.s,
        fit: BoxFit.contain,
        color: isSelected
            ? context.theme.appColors.primaryAccent
            : context.theme.appColors.tertiaryText,
      ),
    );
  }
}

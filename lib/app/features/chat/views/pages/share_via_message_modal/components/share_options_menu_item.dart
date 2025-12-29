// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';

class ShareOptionsMenuItem extends StatelessWidget {
  const ShareOptionsMenuItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.buttonType,
    this.borderColor,
    super.key,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;
  final ButtonType buttonType;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 70.0.s),
      child: TextIconButton(
        icon: icon,
        label: label,
        onPressed: onPressed,
        type: buttonType,
        borderColor: borderColor,
      ),
    );
  }
}

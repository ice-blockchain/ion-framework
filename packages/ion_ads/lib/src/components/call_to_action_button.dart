// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/config/theme_data.dart';

class CallToActionButton extends StatelessWidget {
  const CallToActionButton({required this.child, required this.onPressed, super.key});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.adsSpacing;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: theme.adsColors.primaryAccent,
        textStyle: theme.textOnPrimary.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.borderRadiusDefault),
        ),
        minimumSize: Size(0, spacing.iconSizeDefault),
        padding: EdgeInsets.symmetric(horizontal: spacing.paddingInnerHorizontal),
      ),
      child: child,
    );
  }
}

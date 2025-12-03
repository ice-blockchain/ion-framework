// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/config/theme_data.dart';

class CallToActionButton extends StatelessWidget {
  const CallToActionButton({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilledButton(
      onPressed: () {},
      style: FilledButton.styleFrom(
        backgroundColor: theme.adsColors.primaryAccent,
        textStyle: theme.textOnPrimary.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Set the radius here
        ),
        minimumSize: const Size(0, 30),
        padding: const EdgeInsetsGeometry.symmetric(horizontal: 20),
      ),
      child: child,
    );
  }
}

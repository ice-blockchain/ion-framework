// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/extensions/extensions.dart';

class GradientVerticalDivider extends StatelessWidget {
  const GradientVerticalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.40,
      child: Container(
        height: 25.0.s,
        width: 0.5.s,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              context.theme.appColors.onPrimaryAccent,
              context.theme.appColors.onPrimaryAccent.withValues(alpha: 0.8),
              context.theme.appColors.onPrimaryAccent,
            ],
          ),
        ),
      ),
    );
  }
}

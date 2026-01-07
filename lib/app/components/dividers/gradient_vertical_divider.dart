// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/extensions/extensions.dart';

class GradientVerticalDivider extends StatelessWidget {
  const GradientVerticalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25.0.s,
      width: 0.5.s,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            context.theme.appColors.onPrimaryAccent.withValues(alpha: 0),
            context.theme.appColors.onPrimaryAccent.withValues(alpha: 0.32),
            context.theme.appColors.onPrimaryAccent.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

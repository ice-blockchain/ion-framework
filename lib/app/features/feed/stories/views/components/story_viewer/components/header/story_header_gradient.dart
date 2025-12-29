// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class StoryHeaderGradient extends StatelessWidget {
  const StoryHeaderGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: 0,
      start: 0,
      end: 0,
      child: Container(
        height: 120.0.s,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.1,
            // end: Alignment.bottomCenter,
            colors: [
              context.theme.appColors.primaryText.withValues(alpha: 0.3),
              context.theme.appColors.primaryText.withValues(alpha: 0.15),
              context.theme.appColors.primaryText.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

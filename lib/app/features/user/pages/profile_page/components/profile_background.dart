// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class ProfileBackground extends StatelessWidget {
  const ProfileBackground({
    this.color1,
    this.color2,
    this.disableDarkGradient = false,
    this.child,
    super.key,
  });

  final Color? color1;
  final Color? color2;
  final bool disableDarkGradient;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final childWithBackground = color1 != null && color2 != null
        ? Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color1!, color2!],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
              // Dark overlay gradient
              if (!disableDarkGradient)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
              // Child content
              if (child != null) child!,
            ],
          )
        : ColoredBox(
            color: const Color(0xFFD1D1D5),
            child: child,
          );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: childWithBackground,
    );
  }
}

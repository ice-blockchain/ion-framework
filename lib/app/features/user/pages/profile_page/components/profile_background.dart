// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';

class ProfileBackground extends StatelessWidget {
  const ProfileBackground({
    this.colors,
    this.disableDarkGradient = false,
    this.child,
    super.key,
  });

  final AvatarColors? colors;
  final bool disableDarkGradient;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final targetColors = colors ?? useAvatarFallbackColors;

    return TweenAnimationBuilder<AvatarColors>(
      duration: const Duration(milliseconds: 500),
      tween: _AvatarColorsTween(
        begin: targetColors,
        end: targetColors,
      ),
      builder: (context, animatedColors, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [animatedColors.first, animatedColors.second],
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
            if (this.child != null) this.child!,
          ],
        );
      },
    );
  }
}

class _AvatarColorsTween extends Tween<AvatarColors> {
  _AvatarColorsTween({
    required super.begin,
    required super.end,
  });

  @override
  AvatarColors lerp(double t) {
    return (
      first: Color.lerp(begin!.first, end!.first, t)!,
      second: Color.lerp(begin!.second, end!.second, t)!,
    );
  }
}

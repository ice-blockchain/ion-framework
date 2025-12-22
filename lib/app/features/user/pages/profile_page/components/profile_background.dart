// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/status_bar/status_bar_color_wrapper.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/utils/color.dart';

class ProfileBackground extends HookWidget {
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

    final isDark = useMemoized(
      () => isColorDark(targetColors.first),
      [targetColors.first],
    );

    if (isDark) {
      return StatusBarColorWrapper.light(
        child: ProfileGradientBackground(
          colors: targetColors,
          disableDarkGradient: disableDarkGradient,
          child: child,
        ),
      );
    } else {
      return StatusBarColorWrapper.dark(
        child: ProfileGradientBackground(
          colors: targetColors,
          disableDarkGradient: disableDarkGradient,
          child: child,
        ),
      );
    }
  }
}

class ProfileGradientBackground extends StatelessWidget {
  const ProfileGradientBackground({
    required this.colors,
    required this.disableDarkGradient,
    this.translateY,
    super.key,
    this.child,
  });

  final AvatarColors colors;
  final bool disableDarkGradient;
  final double? translateY;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<AvatarColors>(
      duration: const Duration(milliseconds: 500),
      tween: _AvatarColorsTween(
        begin: colors,
        end: colors,
      ),
      builder: (context, animatedColors, child) {
        final gradientTransform = translateY == null ? null : _GradientTranslate(translateY!);
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [animatedColors.first, animatedColors.second],
                    stops: const [0.0, 1.0],
                    transform: gradientTransform,
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
                        context.theme.appColors.forest.withValues(alpha: 0.4),
                        context.theme.appColors.forest,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 1.0],
                      transform: gradientTransform,
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

class _GradientTranslate extends GradientTransform {
  const _GradientTranslate(this.translateY);

  final double translateY;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(0, translateY, 0);
  }
}

class _AvatarColorsTween extends Tween<AvatarColors> {
  _AvatarColorsTween({
    required super.begin,
    required super.end,
  });

  @override
  AvatarColors lerp(double t) {
    final beginValue = begin;
    final endValue = end;

    if (beginValue == null || endValue == null) {
      return beginValue ?? endValue ?? useAvatarFallbackColors;
    }

    return (
      first: Color.lerp(beginValue.first, endValue.first, t) ?? beginValue.first,
      second: Color.lerp(beginValue.second, endValue.second, t) ?? beginValue.second,
    );
  }
}

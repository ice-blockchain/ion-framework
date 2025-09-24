// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ShutterAnimation extends HookWidget {
  const ShutterAnimation({
    required this.shutterAnimationController,
    super.key,
  });

  final AnimationController shutterAnimationController;

  @override
  Widget build(BuildContext context) {
    final shutterAnimation = useMemoized(
      () {
        return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: shutterAnimationController,
            curve: Curves.easeIn,
          ),
        );
      },
      [shutterAnimationController],
    );

    return IgnorePointer(
      child: AnimatedBuilder(
        builder: (context, widget) {
          return Opacity(
            opacity: shutterAnimation.value,
            child: widget,
          );
        },
        animation: shutterAnimationController,
        child: const ColoredBox(color: Colors.black),
      ),
    );
  }
}

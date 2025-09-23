// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

AnimationController useShutterAnimationController({
  Duration duration = const Duration(milliseconds: 50),
}) {
  final controller = useAnimationController(duration: duration);

  useEffect(
    () {
      void listener(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          controller.reverse();
        }
      }

      controller.addStatusListener(listener);
      return () => controller.removeStatusListener(listener);
    },
    [controller],
  );

  return controller;
}

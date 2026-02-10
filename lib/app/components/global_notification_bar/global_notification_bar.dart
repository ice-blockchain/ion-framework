// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GlobalNotificationBar extends HookConsumerWidget {
  const GlobalNotificationBar({
    required this.child,
    super.key,
  });

  final Widget? child;

  static const animationDuration = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useAnimationController(
      duration: animationDuration,
    );
    final lastChild = useState<Widget?>(null);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    useEffect(
      () {
        if (child != null) {
          lastChild.value = child;
        }
        return null;
      },
      [child],
    );

    useEffect(
      () {
        void handleStatus(AnimationStatus status) {
          if (status == AnimationStatus.dismissed && child == null) {
            lastChild.value = null;
          }
        }

        controller.addStatusListener(handleStatus);
        return () => controller.removeStatusListener(handleStatus);
      },
      [controller, child],
    );

    _controlAnimation(
      isShow: child != null,
      animation: animation,
      controller: controller,
    );

    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: 1,
      child: lastChild.value ?? const SizedBox.shrink(),
    );
  }

  void _controlAnimation({
    required bool isShow,
    required CurvedAnimation animation,
    required AnimationController controller,
  }) {
    if (isShow && animation.status != AnimationStatus.completed) {
      controller.forward();
    } else if (!isShow && animation.status != AnimationStatus.dismissed) {
      controller.animateBack(0, duration: animationDuration);
    }
  }
}

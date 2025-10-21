// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/message_notification/models/message_notification.f.dart';
import 'package:ion/app/components/message_notification/models/message_notification_state.dart';
import 'package:ion/app/components/message_notification/providers/message_notification_notifier_provider.r.dart';
import 'package:ion/app/extensions/extensions.dart';

class MessageNotificationWrapper extends HookConsumerWidget {
  const MessageNotificationWrapper({
    required this.child,
    super.key,
  });

  final Widget child;

  static const animationDuration = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useAnimationController(
      duration: animationDuration,
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    final notification = useState<MessageNotification?>(null);

    final color = switch (notification.value?.state) {
      MessageNotificationState.success => context.theme.appColors.success,
      MessageNotificationState.error => context.theme.appColors.attentionRed,
      MessageNotificationState.info => context.theme.appColors.primaryAccent,
      _ => context.theme.appColors.primaryAccent,
    };

    ref.listen(
      messageNotificationNotifierProvider,
      (_, next) {
        notification.value = next.valueOrNull;

        _controlAnimation(
          isShow: true,
          animation: animation,
          controller: controller,
        );

        Future.delayed(
          const Duration(seconds: 3),
          () {
            _controlAnimation(
              isShow: false,
              animation: animation,
              controller: controller,
            );
          },
        );
      },
    );

    final suffixWidget = notification.value?.suffixWidget;

    return Stack(
      children: [
        child,
        PositionedDirectional(
          start: 16.0.s,
          end: 16.0.s,
          bottom: 94.0.s,
          child: IgnorePointer(
            child: FadeTransition(
              opacity: animation,
              child: Container(
                height: 42.0.s,
                padding: EdgeInsets.all(8.0.s),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12.0.s),
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.appColors.primaryAccent.withValues(alpha: 0.36),
                      blurRadius: 20.0.s,
                      spreadRadius: 0.0.s,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (notification.value?.icon != null) ...[
                          Container(
                            width: 26.0.s,
                            height: 26.0.s,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.theme.appColors.onPrimaryAccent,
                              borderRadius: BorderRadius.circular(8.0.s),
                            ),
                            child: notification.value?.icon,
                          ),
                          SizedBox(width: 10.0.s),
                        ],
                        Text(
                          notification.value?.message ?? '',
                          style: context.theme.appTextThemes.body.copyWith(
                            color: context.theme.appColors.onPrimaryAccent,
                          ),
                        ),
                      ],
                    ),
                    if (suffixWidget != null) suffixWidget,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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

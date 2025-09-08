// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/components/message_notification/message_notification_wrapper.dart';
import 'package:ion/app/components/message_notification/models/message_notification.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_notification_notifier_provider.r.g.dart';

@riverpod
class MessageNotificationNotifier extends _$MessageNotificationNotifier {
  @override
  MessageNotification? build() => null;

  Timer? _hideTimer;

  static const _notificationDuration = Duration(seconds: 3);

  void show(MessageNotification notification) {
    // Prevent bottom sheet from jumping when showing notification
    Future.delayed(
      MessageNotificationWrapper.animationDuration,
      () => state = notification,
    );

    _hideTimer?.cancel();

    _hideTimer = Timer(
      _notificationDuration - MessageNotificationWrapper.animationDuration,
      hide,
    );
  }

  void hide() {
    Future.delayed(
      MessageNotificationWrapper.animationDuration,
      () {
        _hideTimer?.cancel();
        state = null;
      },
    );
  }
}

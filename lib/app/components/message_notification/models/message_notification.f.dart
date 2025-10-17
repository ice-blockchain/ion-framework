// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/components/message_notification/models/message_notification_state.dart';

part 'message_notification.f.freezed.dart';

@freezed
class MessageNotification with _$MessageNotification {
  factory MessageNotification({
    required String message,
    required Widget? icon,
    @Default(MessageNotificationState.info) MessageNotificationState state,
    Widget? suffixWidget,
  }) = _MessageNotification;
}

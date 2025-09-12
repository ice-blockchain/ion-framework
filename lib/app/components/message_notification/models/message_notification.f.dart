// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_notification.f.freezed.dart';

@freezed
class MessageNotification with _$MessageNotification {
  factory MessageNotification({
    required String message,
    required Widget? icon,
  }) = _MessageNotification;
}

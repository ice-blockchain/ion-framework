// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/components/message_notification/models/message_notification.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_notification_notifier_provider.r.g.dart';

@riverpod
class MessageNotificationNotifier extends _$MessageNotificationNotifier {
  @override
  FutureOr<MessageNotification?> build() => null;

  void show(MessageNotification notification) {
    state = AsyncValue.data(notification);
  }
}

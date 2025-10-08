// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_notification_manager.r.g.dart';

///
/// Manages push notifications
///
class PushNotificationManager {
  ///
  /// Clears notifications for a specific conversation
  ///
  /// - Parameters:
  ///   - conversationId: The ID of the conversation to clear notifications for
  ///
  Future<void> clearConversationNotifications(String conversationId) async {
    const channel = MethodChannel('notification_channel');
    await channel.invokeMethod('clearConversationNotifications', {
      'conversationId': conversationId,
    });
  }
}

@riverpod
PushNotificationManager pushNotificationManager(Ref ref) => PushNotificationManager();

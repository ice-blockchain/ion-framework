// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_notification_clear_manager.r.g.dart';

const String _channelName = 'notification_channel';
const String _methodName = 'clearNotificationGroup';
const String _groupIdentifierKey = 'groupIdentifier';

///
/// Manages push notifications clearing
///
class PushNotificationCleaner {
  ///
  /// Cleans notifications for a specific group identifier
  ///
  /// On iOS: matches against threadIdentifier
  /// On Android: matches against notification group and tag
  ///
  /// - Parameters:
  ///   - groupIdentifier: The group identifier to clear notifications for
  ///     (e.g., conversationId, channelId, or any other grouping identifier)
  ///
  void cleanByGroupId(String groupIdentifier) {
    const MethodChannel(_channelName).invokeMethod(_methodName, {
      _groupIdentifierKey: groupIdentifier,
    });
  }

  void cleanByGroupIds(List<String> groupIdentifiers) {
    for (final groupIdentifier in groupIdentifiers) {
      cleanByGroupId(groupIdentifier);
    }
  }
}

@riverpod
PushNotificationCleaner pushNotificationCleaner(Ref ref) => PushNotificationCleaner();

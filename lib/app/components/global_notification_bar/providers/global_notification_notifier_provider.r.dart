// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:ion/app/components/global_notification_bar/global_notification_bar.dart';
import 'package:ion/app/components/global_notification_bar/models/global_notification.dart';
import 'package:ion/app/features/feed/global_notifications/models/feed_global_notification.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_notification_notifier_provider.r.g.dart';

typedef _NotificationItem = ({
  /// A unique identifier for the notification. Can be null for temporary notifications.
  FeedNotificationContentType? key,
  GlobalNotification notification,
  bool isPermanent,
});

@riverpod
class GlobalNotificationNotifier extends _$GlobalNotificationNotifier {
  /// The stack of notifications. The UI will always display the last item.
  final List<_NotificationItem> _stack = [];

  CancelableOperation<void>? _animationOperation;

  @override
  GlobalNotification? build() {
    ref.onDispose(() {
      _animationOperation?.cancel();
    });
    return null;
  }

  static const _notificationDuration = Duration(seconds: 3);
  static const _animationDuration = GlobalNotificationBar.animationDuration;

  /// Shows a notification.
  ///
  /// Use a non-null [key] for permanent or updatable notifications.
  /// If a notification with the same [key] already exists, it will be replaced
  /// and brought to the top of the stack.
  /// Use a null [key] for temporary "fire-and-forget" notifications.
  void show(
    GlobalNotification notification, {
    FeedNotificationContentType? key,
    bool isPermanent = false,
  }) {
    final newItem = (key: key, notification: notification, isPermanent: isPermanent);

    // If the key is not null, it's a permanent/updatable notification.
    // Remove any existing one with the same key before adding the new one.
    if (key != null) {
      _stack.removeWhere((item) => item.key == key);
    }
    _stack.add(newItem);

    // Update the UI to show the new top-most notification.
    _updateUiState();

    // If the notification is not permanent, schedule it to be hidden.
    // This now removes the specific instance, which safely handles null keys.
    if (!isPermanent) {
      Future.delayed(_notificationDuration, () {
        // Check if the item to be removed is the one currently showing.
        final wasHidingCurrent = _stack.isNotEmpty && identical(_stack.last, newItem);

        final removed = _stack.remove(newItem);
        // If the visible notification was removed, update the UI.
        if (removed && wasHidingCurrent) {
          _updateUiState();
        }
      });
    }
  }

  /// Hides a notification identified by its non-null [key].
  ///
  /// This method is intended for explicitly removing permanent notifications.
  /// Temporary notifications (with null keys) hide themselves automatically.
  void hide({FeedNotificationContentType? key}) {
    // This method should only be used to hide notifications with a key.
    // Basically, it's used only for loading notifications.
    if (key == null) return;

    final isHidingCurrent = _stack.isNotEmpty && _stack.last.key == key;

    _stack.removeWhere((item) => item.key == key);

    if (isHidingCurrent) {
      _updateUiState();
    }
  }

  /// A private helper to manage the UI state and its animations.
  ///
  /// This function is responsible for gracefully animating out the old notification
  /// before showing the new one. This prevents jarring UI changes.
  void _updateUiState() {
    _animationOperation?.cancel();

    final future = Future(() async {
      final nextNotification = _stack.lastOrNull?.notification;

      // If the UI is already showing the correct notification, do nothing.
      if (state == nextNotification) {
        return;
      }

      if (state != null) {
        state = null;
        await Future<void>.delayed(_animationDuration);
      }

      state = _stack.lastOrNull?.notification;
    });

    _animationOperation = CancelableOperation.fromFuture(future);
  }
}

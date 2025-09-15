// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:ion/app/components/global_notification_bar/global_notification_bar.dart';
import 'package:ion/app/components/global_notification_bar/models/global_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_notification_notifier_provider.r.g.dart';

/// A private record to hold a notification and its properties within the stack.
typedef _NotificationItem = ({GlobalNotification notification, bool isPermanent});

/// This notifier manages a stack of global notifications.
/// It ensures that temporary notifications can be shown over
/// permanent ones (like uploads) without causing the permanent
/// notification to be lost.
@riverpod
class GlobalNotificationNotifier extends _$GlobalNotificationNotifier {
  /// The stack of notifications. The UI will always display the last item.
  final List<_NotificationItem> _notificationStack = [];
  CancelableOperation<void>? _operation;

  @override
  GlobalNotification? build() {
    // Ensure any pending operations are cancelled when the provider is disposed.
    ref.onDispose(() {
      _operation?.cancel();
    });
    return null;
  }

  static const _notificationDuration = Duration(seconds: 3);
  static const _animationDuration = GlobalNotificationBar.animationDuration;

  /// Shows a notification. If another notification is currently visible,
  /// the old one will be animated out and the new one will be animated in.
  /// The [notification] object itself is used as a unique key.
  void show(GlobalNotification notification, {bool isPermanent = false}) {
    _operation?.cancel();

    final newItem = (notification: notification, isPermanent: isPermanent);

    // If this exact notification is already in the stack, remove the old one.
    // This brings it to the top and prevents duplicates.
    _notificationStack
      ..removeWhere((item) => item.notification == notification)
      ..add(newItem);

    final needsTransition = state != null && state != notification;

    _updateState(
      isTransition: needsTransition,
      onComplete: () {
        if (!isPermanent) {
          // When the duration is up, we hide the notification.
          // The check to see if it's still the top item was removed, as it
          // was preventing underlying notifications from being cleared from the stack.
          // The hide() method is smart enough to only trigger a UI update if the
          // top-most notification is the one being hidden.
          Future.delayed(_notificationDuration, () {
            hide(notification);
          });
        }
      },
    );
  }

  /// Hides a specific notification. If it's the one currently being displayed,
  /// it will be animated out, and the next notification in the stack (if any)
  /// will be animated in. If it's a notification that's not currently visible
  /// (i.e., it's under the top-most one), it will be removed silently.
  void hide(GlobalNotification notification) {
    // Check if the item we're hiding is the one currently on screen BEFORE removing it.
    final isHidingCurrent =
        _notificationStack.isNotEmpty && _notificationStack.last.notification == notification;

    // Use removeWhere for a cleaner and more robust way to remove the item.
    final originalLength = _notificationStack.length;
    _notificationStack.removeWhere((item) => item.notification == notification);
    final removed = _notificationStack.length < originalLength;

    // If we removed an item AND it was the one on screen, we need to update the UI.
    if (removed && isHidingCurrent) {
      _operation?.cancel();
      _updateState(isTransition: true);
    }
  }

  /// A private helper to manage the state and animation transitions.
  /// It ensures a smooth `current -> animate out -> animate in -> next` flow.
  void _updateState({bool isTransition = false, void Function()? onComplete}) {
    final future = Future(() async {
      // 1. If transitioning from an existing notification, animate it out by setting state to null.
      if (isTransition && state != null) {
        state = null;
        await Future<void>.delayed(_animationDuration);
      }

      // 2. Get the next notification that should be at the top of the stack.
      final nextItem = _notificationStack.lastOrNull;

      // 3. If there is a next notification, animate it in by updating the state.
      if (nextItem != null) {
        state = nextItem.notification;
        // This delay is optional but can prevent jank if animations overlap.
        // For simplicity, we assume the widget handles its own "appear" animation.
      }

      // 4. Call the completion callback, which is used to set the hide timer.
      onComplete?.call();
    });

    _operation = CancelableOperation.fromFuture(future);
  }
}

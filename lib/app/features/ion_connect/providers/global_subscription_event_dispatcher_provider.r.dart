// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_event_message_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/follow_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/like_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/mention_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/quote_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/reply_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/repost_notification_handler.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:ion/app/features/user/providers/badge_award_handler.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_subscription_event_dispatcher_provider.r.g.dart';

class GlobalSubscriptionEventDispatcher {
  GlobalSubscriptionEventDispatcher(this.ref, this._handlers);

  final Ref ref;
  final List<GlobalSubscriptionEventHandler?> _handlers;
  final List<EventMessage> _eventQueue = [];
  bool _isProcessing = false;

  void dispatch(EventMessage eventMessage) {
    _eventQueue.add(eventMessage);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (_eventQueue.isNotEmpty) {
        // Take up to 5 events from the queue
        final batchSize = _eventQueue.length > 5 ? 5 : _eventQueue.length;
        final batch = _eventQueue.sublist(0, batchSize);
        _eventQueue.removeRange(0, batchSize);

        // Process the batch sequentially
        for (final eventMessage in batch) {
          final futures = _handlers.nonNulls
              .where((handler) => handler.canHandle(eventMessage))
              .map((handler) => handler.handle(eventMessage));

          await Future.wait(futures);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
}

@riverpod
Future<GlobalSubscriptionEventDispatcher> globalSubscriptionEventDispatcherNotifier(
  Ref ref,
) async {
  return GlobalSubscriptionEventDispatcher(ref, [
    await ref.watch(encryptedMessageEventHandlerProvider.future),
    ref.watch(followNotificationHandlerProvider),
    ref.watch(likeNotificationHandlerProvider),
    ref.watch(mentionNotificationHandlerProvider),
    ref.watch(quoteNotificationHandlerProvider),
    ref.watch(replyNotificationHandlerProvider),
    ref.watch(repostNotificationHandlerProvider),
    ref.watch(badgeAwardHandlerProvider),
  ]);
}

// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_event_message_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/follow_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/like_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/mention_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/quote_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/reply_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/repost_notification_handler.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/events_manager.dart';
import 'package:ion/app/features/user/providers/badge_award_handler.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_subscription_event_dispatcher_provider.r.g.dart';

class GlobalSubscriptionEventDispatcher {
  GlobalSubscriptionEventDispatcher(this.ref, this._eventsManager);

  final Ref ref;
  final EventsManager _eventsManager;

  void dispatch(EventMessage eventMessage) {
    _eventsManager.dispatch(eventMessage);
  }
}

@riverpod
Future<GlobalSubscriptionEventDispatcher> globalSubscriptionEventDispatcherNotifier(
  Ref ref,
) async {
  final handlers = [
    await ref.watch(encryptedMessageEventHandlerProvider.future),
    ref.watch(followNotificationHandlerProvider),
    ref.watch(likeNotificationHandlerProvider),
    ref.watch(mentionNotificationHandlerProvider),
    ref.watch(quoteNotificationHandlerProvider),
    ref.watch(replyNotificationHandlerProvider),
    ref.watch(repostNotificationHandlerProvider),
    ref.watch(badgeAwardHandlerProvider),
  ];

  final eventsManager = EventsManager(ref, handlers);

  return GlobalSubscriptionEventDispatcher(ref, eventsManager);
}

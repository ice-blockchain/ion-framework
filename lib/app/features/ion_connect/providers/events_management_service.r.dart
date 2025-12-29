// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_event_message_handler.r.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/follow_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/like_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/mention_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/quote_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/reply_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/repost_notification_handler.r.dart';
import 'package:ion/app/features/feed/notifications/providers/notifications/token_launch_notification_handler.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:ion/app/features/user/providers/badge_award_handler.r.dart';
import 'package:ion/app/features/user/providers/user_delegation_handler.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/queue.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'events_management_service.r.g.dart';

@riverpod
Future<EventsManagementService> eventsManagementService(Ref ref) async {
  final handlers = [
    await ref.watch(encryptedMessageEventHandlerProvider.future),
    ref.watch(followNotificationHandlerProvider),
    ref.watch(likeNotificationHandlerProvider),
    ref.watch(mentionNotificationHandlerProvider),
    ref.watch(quoteNotificationHandlerProvider),
    ref.watch(replyNotificationHandlerProvider),
    ref.watch(repostNotificationHandlerProvider),
    ref.watch(badgeAwardHandlerProvider),
    ref.watch(userDelegationHandlerProvider),
    ref.watch(tokenLaunchNotificationHandlerProvider),
  ];

  final manager = EventsManagementService(handlers);

  final lifecycleSubscription = ref.listen<AppLifecycleState>(
    appLifecycleProvider,
    (previous, next) {
      if (next != AppLifecycleState.resumed) {
        manager.cancelAllOperations();
      }
    },
  );

  final authSubscription = ref.listen(authProvider, (previous, next) {
    final isAuthenticated = next.valueOrNull?.isAuthenticated ?? false;
    if (!isAuthenticated) {
      manager.cancelAllOperations();
    }
  });

  ref.onDispose(() {
    manager.cancelAllOperations();
    lifecycleSubscription.close();
    authSubscription.close();
  });

  return manager;
}

class EventsManagementService {
  EventsManagementService(List<GlobalSubscriptionEventHandler?> handlers, {int maxConcurrent = 10})
      : _handlers = handlers.whereType<GlobalSubscriptionEventHandler>().toList(),
        _taskQueue = ConcurrentTasksQueue(maxConcurrent: maxConcurrent);

  final ConcurrentTasksQueue _taskQueue;
  final List<GlobalSubscriptionEventHandler> _handlers;

  void dispatch(EventMessage eventMessage) {
    _taskQueue.add(() => _processEvent(eventMessage));
  }

  void cancelAllOperations() {
    _taskQueue.cancelAll();
  }

  Future<void> _processEvent(EventMessage eventMessage) async {
    final futures =
        _handlers.where((handler) => handler.canHandle(eventMessage)).map((handler) async {
      try {
        await handler.handle(eventMessage);
      } catch (e, stack) {
        Logger.error(
          e,
          message: 'Error handling event in events manager: $e',
          stackTrace: stack,
        );
      }
    });

    await Future.wait(futures);
  }
}

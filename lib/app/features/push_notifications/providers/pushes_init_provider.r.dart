// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/push_notifications/providers/configure_firebase_app_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/configure_firebase_messaging_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/foreground_messages_handler_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/notification_response_handler_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/push_subscription_sync_provider.r.dart';
import 'package:ion/app/utils/functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pushes_init_provider.r.g.dart';

@Riverpod(keepAlive: true)
void pushesInit(Ref ref) {
  ref
    ..listen(configureFirebaseAppProvider, noop)
    ..listen(configureFirebaseMessagingProvider, noop)
    ..listen(pushSubscriptionSyncProvider, noop)
    ..listen(notificationResponseHandlerProvider, noop)
    ..listen(foregroundMessagesHandlerProvider, noop);
}

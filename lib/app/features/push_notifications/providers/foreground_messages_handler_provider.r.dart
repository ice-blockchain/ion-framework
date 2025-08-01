// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/providers/gift_unwrap_service_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/push_notifications/data/models/ion_connect_push_data_payload.f.dart';
import 'package:ion/app/features/push_notifications/providers/configure_firebase_app_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/notification_data_parser_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/firebase/firebase_messaging_service_provider.r.dart';
import 'package:ion/app/services/local_notifications/local_notifications.r.dart';
import 'package:ion/app/services/uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'foreground_messages_handler_provider.r.g.dart';

@Riverpod(keepAlive: true)
class ForegroundMessagesHandler extends _$ForegroundMessagesHandler {
  @override
  FutureOr<void> build() async {
    final firebaseAppConfigured = ref.watch(configureFirebaseAppProvider).valueOrNull ?? false;
    if (firebaseAppConfigured) {
      final firebaseMessagingService = ref.watch(firebaseMessagingServiceProvider);
      final subscription = firebaseMessagingService.onMessage().listen(_handleForegroundMessage);
      ref.onDispose(subscription.cancel);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage response) async {
    final data = await IonConnectPushDataPayload.fromEncoded(
      response.data,
      unwrapGift: (eventMassage) async {
        final giftUnwrapService = await ref.read(giftUnwrapServiceProvider.future);

        final event = await giftUnwrapService.unwrap(eventMassage);
        final userMetadata =
            await ref.read(userMetadataFromDbOnceProvider(event.masterPubkey).future);

        return (event, userMetadata);
      },
    );

    if (await _shouldSkip(data: data)) {
      return;
    }

    final parser = await ref.read(notificationDataParserProvider.future);
    final parsedData = await parser.parse(
      data,
      getFundsRequestData: (eventMessage) =>
          ref.read(fundsRequestDisplayDataProvider(eventMessage).future),
      getTransactionData: (eventMessage) =>
          ref.read(transactionDisplayDataProvider(eventMessage).future),
    );

    final title = parsedData?.title ?? response.notification?.title;
    final body = parsedData?.body ?? response.notification?.body;

    if (title == null || body == null) {
      return;
    }

    final notificationsService = await ref.read(localNotificationsServiceProvider.future);
    await notificationsService.showNotification(
      id: generateUuid().hashCode,
      title: title,
      body: body,
      payload: jsonEncode(response.data),
    );
  }

  Future<bool> _shouldSkip({
    required IonConnectPushDataPayload data,
  }) async {
    // Skipping gift wraps with own events
    if (data.event.kind == IonConnectGiftWrapEntity.kind) {
      final giftUnwrapService = await ref.watch(giftUnwrapServiceProvider.future);
      final currentPubkey = ref.watch(currentPubkeySelectorProvider);

      if (currentPubkey == null) {
        return true;
      }

      final rumor = await giftUnwrapService.unwrap(data.event);

      return rumor.masterPubkey == currentPubkey;
    }
    return false;
  }
}

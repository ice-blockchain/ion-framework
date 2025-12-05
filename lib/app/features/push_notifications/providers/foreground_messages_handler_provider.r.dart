// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/providers/gift_unwrap_service_provider.r.dart';
import 'package:ion/app/features/chat/providers/muted_conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message_provider.r.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/push_notifications/data/models/ion_connect_push_data_payload.f.dart';
import 'package:ion/app/features/push_notifications/providers/configure_firebase_app_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/notification_data_parser_provider.r.dart';
import 'package:ion/app/features/user/providers/muted_users_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/firebase/firebase_messaging_service_provider.r.dart';
import 'package:ion/app/services/local_notifications/local_notifications.r.dart';
import 'package:ion/app/services/logger/logger.dart';
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
    Logger.log('☁️ Foreground push notification received: ${response.toMap()}');

    final data = await IonConnectPushDataPayload.fromEncoded(
      response.data,
      unwrapGift: (eventMassage) async {
        // Attempt to decrypt GiftWrap message.
        // If decryption fails (e.g., message encrypted for another user),
        // this is expected - we return (null, null) to allow notification display.
        // User can switch accounts to view the content.
        try {
          final giftUnwrapService = await ref.read(giftUnwrapServiceProvider.future);

          final event = await giftUnwrapService.unwrap(eventMassage);
          final userMetadata = await ref.read(
            userMetadataProvider(event.masterPubkey).future,
          );

          return (event, userMetadata);
        } catch (error) {
          // Expected: message encrypted for another user
          return (null, null);
        }
      },
    );

    if (await _shouldSkipOwnGiftWrap(data: data)) {
      return;
    }

    // Skip notifications for self-interactions (e.g., quoting/reposting own content)
    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentPubkey != null && data.isSelfInteraction(currentPubkey: currentPubkey)) {
      return;
    }

    // Skip notifications from muted users or muted conversations
    if (_shouldSkipMutedNotification(data)) {
      return;
    }

    final parser = await ref.read(notificationDataParserProvider.future);
    final parsedData = await parser.parse(
      data,
      getFundsRequestData: (eventMessage) =>
          ref.read(fundsRequestDisplayDataProvider(eventMessage).future),
      getTransactionData: (eventMessage) =>
          ref.read(transactionDisplayDataProvider(eventMessage).future),
      getRelatedEntity: (eventReference) =>
          ref.read(ionConnectEntityWithCountersProvider(eventReference: eventReference).future),
    );

    final title = parsedData?.title ?? response.notification?.title;
    final body = parsedData?.body ?? response.notification?.body;

    if (title == null || body == null) {
      return;
    }

    final avatar = parsedData?.avatar;
    final media = parsedData?.media;

    if (_shouldSkipChatPush(data, parsedData?.notificationType)) {
      return;
    }

    final notificationsService = await ref.read(localNotificationsServiceProvider.future);
    await notificationsService.showNotification(
      title: title,
      body: body,
      payload: jsonEncode(response.data),
      icon: avatar,
      attachment: media,
      groupKey: parsedData?.groupKey,
    );
  }

  bool _shouldSkipMutedNotification(IonConnectPushDataPayload data) {
    // Check if this is a gift wrap (chat) notification
    if (data.event.kind != IonConnectGiftWrapEntity.kind) {
      return false;
    }

    // Get the sender's pubkey from decrypted event
    final decryptedEvent = data.decryptedEvent;
    if (decryptedEvent == null) {
      return false;
    }

    final senderPubkey = decryptedEvent.masterPubkey;

    // Check if sender is muted
    final mutedUsers = ref.read(cachedMutedUsersProvider)?.data.masterPubkeys ?? [];
    if (mutedUsers.contains(senderPubkey)) {
      return true;
    }

    // Check if conversation is muted
    final mutedConversations = ref.read(mutedConversationsProvider).valueOrNull;
    if (mutedConversations != null) {
      final mutedPubkeys = mutedConversations.data.masterPubkeys;
      if (mutedPubkeys.contains(senderPubkey)) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _shouldSkipOwnGiftWrap({
    required IonConnectPushDataPayload data,
  }) async {
    if (data.event.kind == IonConnectGiftWrapEntity.kind) {
      final currentPubkey = ref.watch(currentPubkeySelectorProvider);

      // If no user is logged in, skip the notification
      if (currentPubkey == null) {
        return true;
      }

      if (data.decryptedEvent != null) {
        // Skip if message is from current user (self-message)
        return data.decryptedEvent!.masterPubkey == currentPubkey;
      }

      // If decryptedEvent is null, message is encrypted for another user - show notification
      return false;
    }

    return false;
  }

  bool _shouldSkipChatPush(
    IonConnectPushDataPayload data,
    PushNotificationType? notificationType,
  ) {
    final isChatPush = notificationType?.isChat ?? false;
    final rootNavigatorKeyContext = rootNavigatorKey.currentContext;

    final decryptedEventMasterPubkey = data.decryptedEvent?.masterPubkey;
    if (decryptedEventMasterPubkey != null &&
        isChatPush &&
        rootNavigatorKeyContext != null &&
        rootNavigatorKeyContext.mounted) {
      final router = GoRouter.of(rootNavigatorKeyContext);
      final lastMatch = router.routerDelegate.currentConfiguration.last;
      final currentRouteMatchList = lastMatch is ImperativeRouteMatch
          ? lastMatch.matches
          : router.routerDelegate.currentConfiguration;

      final currentPath = currentRouteMatchList.uri.toString();

      // Skip push if current route is already for the same chat
      if (currentPath.contains(decryptedEventMasterPubkey)) {
        return true;
      }
    }

    return false;
  }
}

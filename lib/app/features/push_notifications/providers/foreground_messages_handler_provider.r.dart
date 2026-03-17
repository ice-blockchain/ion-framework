// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/providers/gift_unwrap_service_provider.r.dart';
import 'package:ion/app/features/chat/providers/conversation_request_approval_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message_provider.r.dart';
import 'package:ion/app/features/core/providers/main_wallet_provider.r.dart';
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

    // Check if this is a generic campaign notification (has notification but not IonConnect data)
    final hasNotification = response.notification != null;
    final hasIonConnectData = response.data.containsKey('event');

    // Handle generic notifications (campaigns, deep link notifications)
    if (hasNotification && !hasIonConnectData) {
      final title = response.notification?.title;
      final body = response.notification?.body;

      if (title != null && body != null) {
        final notificationsService = await ref.read(localNotificationsServiceProvider.future);
        await notificationsService.showNotification(
          title: title,
          body: body,
          payload: jsonEncode(response.data),
          conversationStyle: false,
        );
      }
      return;
    }

    // Handle IonConnect notifications
    try {
      final data = await IonConnectPushDataPayload.fromEncoded(
        response.data,
        unwrapGift: (eventMassage) async {
          final giftUnwrapService = await ref.read(giftUnwrapServiceProvider.future);

          final event = await giftUnwrapService.unwrap(eventMassage);
          final userMetadata = await ref.read(
            userMetadataProvider(event.masterPubkey).future,
          );

          return (event, userMetadata);
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
      if (await _shouldSkipMutedNotification(data)) {
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
        // If push belongs to another account on this device, current account can't decrypt it.
        // Show generic fallback so user can tap and switch account in notification response handler.
        if (data.event.kind == IonConnectGiftWrapEntity.kind && data.decryptedEvent == null) {
          final fallback = await _buildEncryptedGiftWrapFallback(data);
          final notificationsService = await ref.read(localNotificationsServiceProvider.future);
          await notificationsService.showNotification(
            title: fallback.$1,
            body: fallback.$2,
            payload: jsonEncode(response.data),
            conversationStyle: false,
          );
        }
        return;
      }

      final avatar = parsedData?.avatar;
      final media = parsedData?.media;

      if (await _shouldSkipRequestChatPush(
        data: data,
        notificationType: parsedData?.notificationType,
        groupKey: parsedData?.groupKey,
      )) {
        return;
      }

      if (_shouldSkipChatPush(data, parsedData?.notificationType)) {
        return;
      }

      // When notification is for another local account, append account label so user can tell.
      var displayBody = body;
      final recipientPubkey = data.recipientPubkey;
      if (recipientPubkey != null &&
          currentPubkey != null &&
          !data.isRecipient(currentPubkey)) {
        final accountLabel = await _resolveRecipientAccountLabel(recipientPubkey);
        final context = rootNavigatorKey.currentContext;
        if (accountLabel != null && context != null && context.mounted) {
          final suffix = context.i18n.notification_for_account(accountLabel);
          displayBody = '$body $suffix';
        }
      }

      final notificationsService = await ref.read(localNotificationsServiceProvider.future);
      await notificationsService.showNotification(
        title: title,
        body: displayBody,
        payload: jsonEncode(response.data),
        icon: avatar,
        attachment: media,
        groupKey: parsedData?.groupKey,
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Error handling IonConnect foreground push',
      );
    }
  }

  Future<bool> _shouldSkipMutedNotification(IonConnectPushDataPayload data) async {
    // Check if this is a gift wrap (chat) notification
    if (data.event.kind != IonConnectGiftWrapEntity.kind) {
      return false;
    }

    // Get the sender's pubkey from decrypted event
    final decryptedEvent = data.decryptedEvent;
    if (decryptedEvent == null) {
      return false;
    }

    final senderMasterPubkey = decryptedEvent.masterPubkey;

    // Check if sender is muted
    // For one-to-one chats it is enough to check muted users
    final mutedUsers = await ref.read(mutedUsersProvider.future);
    if (mutedUsers.contains(senderMasterPubkey)) {
      return true;
    }

    return false;
  }

  Future<bool> _shouldSkipOwnGiftWrap({
    required IonConnectPushDataPayload data,
  }) async {
    if (data.event.kind == IonConnectGiftWrapEntity.kind) {
      final currentPubkey = ref.read(currentPubkeySelectorProvider);

      // If no user is logged in, skip the notification
      if (currentPubkey == null) {
        return true;
      }

      if (data.decryptedEvent != null) {
        // Skip only true self-messages for the current account.
        // If message is sent by current account but addressed to another local account,
        // we should still show fallback notification to allow account switch.
        final isSelfMessage = data.decryptedEvent!.masterPubkey == currentPubkey;
        final isForCurrentUser = data.isRecipient(currentPubkey);
        return isSelfMessage && isForCurrentUser;
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

  Future<bool> _shouldSkipRequestChatPush({
    required IonConnectPushDataPayload data,
    required PushNotificationType? notificationType,
    required String? groupKey,
  }) async {
    if (!(notificationType?.isChat ?? false)) {
      return false;
    }

    final conversationId = groupKey;
    final senderMasterPubkey = data.decryptedEvent?.masterPubkey;

    if (conversationId == null || senderMasterPubkey == null) {
      return false;
    }

    try {
      final approval = await ref.read(
        conversationRequestApprovalProvider(
          conversationId,
          isIncomingContext: true,
          senderMasterPubkey: senderMasterPubkey,
        ).future,
      );

      return approval == ConversationRequestApprovalState.pending;
    } catch (_) {
      return false;
    }
  }

  Future<(String, String)> _buildEncryptedGiftWrapFallback(IonConnectPushDataPayload data) async {
    final entity = data.mainEntity;
    if (entity is! IonConnectGiftWrapEntity || entity.data.relatedPubkeys.isEmpty) {
      return ('Encrypted message', 'Open notification to view');
    }

    final recipientPubkey = entity.data.relatedPubkeys.first.value;
    var recipientLabel = 'another account';
    final recipientProfileName = await _resolveRecipientProfileName(recipientPubkey);
    if (recipientProfileName != null) {
      recipientLabel = recipientProfileName;
    }

    final authState = await ref.read(authProvider.future);
    final identities = authState.authenticatedIdentityKeyNames;
    if (identities.isNotEmpty) {
      final pubkeyResults = await Future.wait(
        identities.map(
          (identityKeyName) => ref.read(userPubkeyByIdentityKeyNameProvider(identityKeyName).future),
        ),
      );

      for (final entry in identities.asMap().entries) {
        if (pubkeyResults[entry.key] == recipientPubkey) {
          recipientLabel = recipientProfileName ?? entry.value;
          break;
        }
      }
    }

    return (
      'Encrypted message',
      'From: encrypted sender. To: $recipientLabel. Tap to open.',
    );
  }

  /// Resolves a human-readable label for the account (recipient pubkey).
  /// Prefers displayName/username from metadata, or identity key name if it's a local account.
  Future<String?> _resolveRecipientAccountLabel(String recipientPubkey) async {
    final profileName = await _resolveRecipientProfileName(recipientPubkey);
    if (profileName != null && profileName.isNotEmpty) {
      return profileName;
    }

    final authState = await ref.read(authProvider.future);
    final identities = authState.authenticatedIdentityKeyNames;
    if (identities.isEmpty) {
      return 'another account';
    }

    final pubkeyResults = await Future.wait(
      identities.map(
        (identityKeyName) =>
            ref.read(userPubkeyByIdentityKeyNameProvider(identityKeyName).future),
      ),
    );
    for (final entry in identities.asMap().entries) {
      if (pubkeyResults[entry.key] == recipientPubkey) {
        return entry.value;
      }
    }

    return 'another account';
  }

  Future<String?> _resolveRecipientProfileName(String recipientPubkey) async {
    try {
      final metadata = await ref.read(userMetadataProvider(recipientPubkey).future);
      if (metadata == null) {
        return null;
      }

      final displayName = metadata.data.trimmedDisplayName;
      if (displayName.isNotEmpty) {
        return displayName;
      }

      final username = metadata.data.name.trim();
      if (username.isNotEmpty) {
        return username;
      }
    } catch (_) {
      // Best-effort name resolution for fallback notification text.
    }

    return null;
  }

}

// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_deletion_request_handler.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_direct_message_handler.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_direct_message_reaction_handler.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_direct_message_status_handler.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_repost_handler.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/gift_unwrap_service_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_e2ee_message_status_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_encrypted_event_message_handler.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/user_block/providers/encrypted_blocked_users_handler.r.dart';
import 'package:ion/app/features/wallets/providers/fund_request_handler.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_asset_handler.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'encrypted_event_message_handler.r.g.dart';

class EncryptedMessageEventHandler implements GlobalSubscriptionEventHandler {
  EncryptedMessageEventHandler({
    required this.handlers,
    required this.masterPubkey,
    required this.conversationDao,
    required this.giftUnwrapService,
    required this.processedGiftWrapDao,
    required this.conversationMessageDao,
    required this.conversationMessageDataDao,
    required this.sendE2eeMessageStatusService,
  });

  final List<GlobalSubscriptionEncryptedEventMessageHandler?> handlers;
  final String masterPubkey;
  final ConversationDao conversationDao;
  final GiftUnwrapService giftUnwrapService;
  final ProcessedGiftWrapDao processedGiftWrapDao;
  final ConversationMessageDao conversationMessageDao;
  final ConversationMessageDataDao conversationMessageDataDao;
  final SendE2eeMessageStatusService sendE2eeMessageStatusService;

  @override
  bool canHandle(EventMessage eventMessage) {
    return eventMessage.kind == IonConnectGiftWrapEntity.kind;
  }

  @override
  Future<void> handle(EventMessage eventMessage) async {
    final wrapEntity = IonConnectGiftWrapEntity.fromEventMessage(eventMessage);

    // Unwrap the gift only if it contains a direct message kind
    final containsDirectMessageKind = wrapEntity.data.kinds
        .any((kinds) => kinds.contains(ReplaceablePrivateDirectMessageEntity.kind.toString()));

    EventMessage? rumor;
    
    if (containsDirectMessageKind) {
      rumor = await giftUnwrapService.unwrap(eventMessage);
      await _checkReceivedStatusForDirectMessage(rumor);
    }

    // Check if the gift wrap has already been processed
    final isAlreadyProcessed =
        await processedGiftWrapDao.isGiftWrapAlreadyProcessed(giftWrapId: eventMessage.id);

    if (isAlreadyProcessed) {
      return;
    }

    // Unwrap the gift if not already done
    rumor ??= await giftUnwrapService.unwrap(eventMessage);

    // Process with all handlers that can handle this entity
    final futures = handlers.nonNulls
        .where((handler) => handler.canHandle(entity: wrapEntity))
        .map((handler) async {
      final eventReference = await handler.handle(rumor!);
      // Always re-process Deletion Requests, otherwise mark as processed
      if (eventReference != null && rumor.kind != DeletionRequestEntity.kind) {
        await processedGiftWrapDao.add(
          eventReference: eventReference,
          giftWrapId: eventMessage.id,
        );
      }
    });

    await Future.wait(futures);
  }

  Future<void> _checkReceivedStatusForDirectMessage(EventMessage rumor) async {
    final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(rumor);
    final eventReference = entity.toEventReference();

    // Make sure conversation and message are not deleted before sending "received" status
    if (!await conversationDao.conversationIsNotDeleted(
          entity.data.conversationId,
          entity.createdAt,
        ) ||
        !await conversationMessageDao.messageIsNotDeleted(eventReference)) {
      return;
    }

    final currentStatus = await conversationMessageDataDao.checkMessageStatus(
      masterPubkey: masterPubkey,
      eventReference: eventReference,
    );

    if (currentStatus == null || currentStatus.index < MessageDeliveryStatus.received.index) {
      // Notify rest of the participants that the message was received
      // by the current user
      unawaited(
        sendE2eeMessageStatusService.sendMessageStatus(
          messageEventMessage: rumor,
          status: MessageDeliveryStatus.received,
        ),
      );
    }

    // If we recovered keypair, current user will not have "read" message status
    // as we don't send it
    if (rumor.masterPubkey == masterPubkey) {
      await conversationMessageDataDao.addOrUpdateStatus(
        pubkey: rumor.pubkey,
        masterPubkey: rumor.masterPubkey,
        status: MessageDeliveryStatus.read,
        messageEventReference: eventReference,
      );
    }
  }
}

@riverpod
Future<EncryptedMessageEventHandler> encryptedMessageEventHandler(Ref ref) async {
  keepAliveWhenAuthenticated(ref);
  final handlers = [
    ref.watch(encryptedDirectMessageStatusHandlerProvider),
    await ref.watch(encryptedDirectMessageHandlerProvider.future),
    ref.watch(encryptedDirectMessageReactionHandlerProvider),
    await ref.watch(encryptedDeletionRequestHandlerProvider.future),
    ref.watch(encryptedRepostHandlerProvider),
    ref.watch(encryptedBlockedUserHandlerProvider),
    await ref.watch(fundsRequestHandlerProvider.future),
    await ref.watch(walletAssetHandlerProvider.future),
  ];

  final masterPubkey = ref.watch(currentPubkeySelectorProvider);

  if (masterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  return EncryptedMessageEventHandler(
    handlers: handlers,
    masterPubkey: masterPubkey,
    conversationDao: ref.watch(conversationDaoProvider),
    processedGiftWrapDao: ref.watch(processedGiftWrapDaoProvider),
    conversationMessageDao: ref.watch(conversationMessageDaoProvider),
    giftUnwrapService: await ref.watch(giftUnwrapServiceProvider.future),
    conversationMessageDataDao: ref.watch(conversationMessageDataDaoProvider),
    sendE2eeMessageStatusService: await ref.watch(sendE2eeMessageStatusServiceProvider.future),
  );
}

// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_deletion_request_handler.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_direct_message_handler.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_direct_message_reaction_handler.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_direct_message_status_handler.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_repost_handler.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/gift_unwrap_service_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
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
    required this.giftUnwrapService,
    required this.eventMessageDao,
  });

  final List<GlobalSubscriptionEncryptedEventMessageHandler?> handlers;
  final GiftUnwrapService giftUnwrapService;
  final EventMessageDao eventMessageDao;

  @override
  bool canHandle(EventMessage eventMessage) {
    return eventMessage.kind == IonConnectGiftWrapEntity.kind;
  }

  @override
  Future<void> handle(EventMessage eventMessage) async {
    final isAlreadProcessed = await eventMessageDao.isExistByWrapId(eventMessage.id);

    if (isAlreadProcessed) {
      return;
    }

    final entity = IonConnectGiftWrapEntity.fromEventMessage(eventMessage);

    final rumor = await giftUnwrapService.unwrap(eventMessage);

    await eventMessageDao.add(rumor, wrapId: eventMessage.id);

    final futures = handlers.nonNulls
        .where((handler) => handler.canHandle(entity: entity))
        .map((handler) => handler.handle(rumor));

    unawaited(Future.wait(futures));
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

  return EncryptedMessageEventHandler(
    handlers: handlers,
    giftUnwrapService: await ref.watch(giftUnwrapServiceProvider.future),
    eventMessageDao: ref.watch(eventMessageDaoProvider),
  );
}

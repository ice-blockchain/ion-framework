// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_message_reaction_data.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_encrypted_event_message_handler.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'encrypted_direct_message_status_handler.r.g.dart';

class EncryptedDirectMessageStatusHandler extends GlobalSubscriptionEncryptedEventMessageHandler {
  EncryptedDirectMessageStatusHandler({
    required this.conversationDao,
    required this.conversationMessageDao,
    required this.conversationMessageDataDao,
  });

  final ConversationDao conversationDao;
  final ConversationMessageDao conversationMessageDao;
  final ConversationMessageDataDao conversationMessageDataDao;

  @override
  bool canHandle({
    required IonConnectGiftWrapEntity entity,
  }) {
    return entity.data.kinds.containsList([
      PrivateMessageReactionEntity.kind.toString(),
    ]);
  }

  @override
  Future<EventReference> handle(EventMessage rumor) async {
    final entity = PrivateMessageReactionEntity.fromEventMessage(rumor);

    if (await conversationMessageDao.messageIsNotDeleted(entity.data.reference)) {
      await conversationMessageDataDao.addOrUpdateStatus(
        messageEventReference: entity.data.reference,
        pubkey: rumor.pubkey,
        masterPubkey: rumor.masterPubkey,
        updateAllBefore: rumor.createdAt.toDateTime,
        status: MessageDeliveryStatus.values.byName(entity.data.content),
      );
    }
    return entity.toEventReference();
  }
}

@riverpod
EncryptedDirectMessageStatusHandler encryptedDirectMessageStatusHandler(Ref ref) =>
    EncryptedDirectMessageStatusHandler(
      conversationDao: ref.watch(conversationDaoProvider),
      conversationMessageDao: ref.watch(conversationMessageDaoProvider),
      conversationMessageDataDao: ref.watch(conversationMessageDataDaoProvider),
    );

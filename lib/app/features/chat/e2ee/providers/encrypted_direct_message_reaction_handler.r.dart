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

part 'encrypted_direct_message_reaction_handler.r.g.dart';

class EncryptedDirectMessageReactionHandler extends GlobalSubscriptionEncryptedEventMessageHandler {
  EncryptedDirectMessageReactionHandler({
    required this.eventMessageDao,
    required this.conversationDao,
    required this.conversationMessageDao,
    required this.conversationMessageReactionDao,
  });

  final EventMessageDao eventMessageDao;
  final ConversationDao conversationDao;
  final ConversationMessageDao conversationMessageDao;
  final ConversationMessageReactionDao conversationMessageReactionDao;

  @override
  bool canHandle({
    required IonConnectGiftWrapEntity entity,
  }) {
    return entity.data.kinds.containsDeep([
      PrivateMessageReactionEntity.kind.toString(),
      PrivateMessageReactionEntity.kind.toString(),
    ]);
  }

  @override
  Future<EventReference> handle(EventMessage rumor) async {
    final entity = PrivateMessageReactionEntity.fromEventMessage(rumor);
    if (await conversationMessageReactionDao.reactionIsNotDeleted(entity) &&
        await conversationMessageDao.messageIsNotDeleted(entity.data.reference)) {
      await conversationMessageReactionDao.add(
        reactionEvent: rumor,
        eventMessageDao: eventMessageDao,
      );
    }
    return entity.toEventReference();
  }
}

@riverpod
EncryptedDirectMessageReactionHandler encryptedDirectMessageReactionHandler(Ref ref) =>
    EncryptedDirectMessageReactionHandler(
      conversationDao: ref.watch(conversationDaoProvider),
      eventMessageDao: ref.watch(eventMessageDaoProvider),
      conversationMessageDao: ref.watch(conversationMessageDaoProvider),
      conversationMessageReactionDao: ref.watch(conversationMessageReactionDaoProvider),
    );

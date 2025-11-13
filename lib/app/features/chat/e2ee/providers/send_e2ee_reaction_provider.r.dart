// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_message_reaction_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/conversation_pubkeys_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_e2ee_reaction_provider.r.g.dart';

@riverpod
Future<SendE2eeReactionService> sendE2eeReactionService(Ref ref) async {
  final sendE2eeChatMessageService = ref.read(sendE2eeChatMessageServiceProvider);
  final eventSigner = await ref.watch(currentUserIonConnectEventSignerProvider.future);

  return SendE2eeReactionService(
    eventSigner: eventSigner,
    sendE2eeChatMessageService: sendE2eeChatMessageService,
    currentUserMasterPubkey: ref.watch(currentPubkeySelectorProvider) ?? '',
    conversationPubkeysNotifier: ref.watch(conversationPubkeysProvider.notifier),
    eventMessageDaoProvider: ref.watch(eventMessageDaoProvider),
    conversationMessageDataDaoProvider: ref.watch(conversationMessageDataDaoProvider),
    conversationMessageReactionDaoProvider: ref.watch(conversationMessageReactionDaoProvider),
  );
}

class SendE2eeReactionService {
  SendE2eeReactionService({
    required this.eventSigner,
    required this.currentUserMasterPubkey,
    required this.sendE2eeChatMessageService,
    required this.conversationPubkeysNotifier,
    required this.eventMessageDaoProvider,
    required this.conversationMessageDataDaoProvider,
    required this.conversationMessageReactionDaoProvider,
  });

  final EventSigner? eventSigner;
  final String currentUserMasterPubkey;
  final ConversationPubkeys conversationPubkeysNotifier;
  final SendE2eeChatMessageService sendE2eeChatMessageService;
  final EventMessageDao eventMessageDaoProvider;
  final ConversationMessageDataDao conversationMessageDataDaoProvider;
  final ConversationMessageReactionDao conversationMessageReactionDaoProvider;

  Future<void> sendReaction({
    required String content,
    required EventMessage kind14Rumor,
  }) async {
    final kind14Event = ReplaceablePrivateDirectMessageEntity.fromEventMessage(kind14Rumor);
    final messageReactionEventMessage = await PrivateMessageReactionEntityData(
      content: content,
      masterPubkey: currentUserMasterPubkey,
      reference: kind14Event.toEventReference(),
    ).toEventMessage(NoPrivateSigner(eventSigner!.publicKey));

    await conversationMessageReactionDaoProvider.add(
      eventMessageDao: eventMessageDaoProvider,
      reactionEvent: messageReactionEventMessage,
    );

    final privateDirectMessageEntity =
        ReplaceablePrivateDirectMessageData.fromEventMessage(kind14Rumor);

    final participantsMasterPubkeys =
        privateDirectMessageEntity.relatedPubkeys?.map((tag) => tag.value).toList();

    if (participantsMasterPubkeys == null) {
      throw ParticipantsMasterPubkeysNotFoundException(kind14Rumor.id);
    }

    final participantsKeysMap =
        await conversationPubkeysNotifier.fetchUsersKeys(participantsMasterPubkeys);

    await Future.wait(
      participantsMasterPubkeys.map((masterPubkey) async {
        final pubkeys = participantsKeysMap[masterPubkey];
        if (pubkeys == null) {
          throw UserPubkeyNotFoundException(masterPubkey);
        }
        await _sendReactionToPubkeys(
          pubkeys: pubkeys,
          masterPubkey: masterPubkey,
          eventMessage: messageReactionEventMessage,
        );
      }),
    );
  }

  Future<void> _sendReactionToPubkeys({
    required List<String> pubkeys,
    required String masterPubkey,
    required EventMessage eventMessage,
  }) async {
    final entity = PrivateMessageReactionEntity.fromEventMessage(eventMessage);
    final eventReference = entity.toEventReference();
    for (final pubkey in pubkeys) {
      try {
        await conversationMessageDataDaoProvider.addOrUpdateStatus(
          pubkey: pubkey,
          masterPubkey: masterPubkey,
          status: MessageDeliveryStatus.created,
          messageEventReference: eventReference,
        );

        await sendE2eeChatMessageService.sendWrappedMessage(
          pubkey: pubkey,
          eventSigner: eventSigner!,
          masterPubkey: masterPubkey,
          eventMessage: eventMessage,
          wrappedKinds: [
            PrivateMessageReactionEntity.kind.toString(),
            PrivateMessageReactionEntity.kind.toString(),
          ],
        );

        await conversationMessageDataDaoProvider.addOrUpdateStatus(
          pubkey: pubkey,
          masterPubkey: masterPubkey,
          status: MessageDeliveryStatus.sent,
          messageEventReference: eventReference,
        );
      } catch (_) {
        await conversationMessageDataDaoProvider.addOrUpdateStatus(
          pubkey: pubkey,
          masterPubkey: masterPubkey,
          status: MessageDeliveryStatus.failed,
          messageEventReference: eventReference,
        );
      }
    }
  }

  Future<void> resendReaction({required EventMessage eventMessage}) async {
    final entity = PrivateMessageReactionEntity.fromEventMessage(eventMessage);

    final failedKind16Participants = await conversationMessageDataDaoProvider.getFailedParticipants(
      eventReference: entity.toEventReference(),
    );

    if (failedKind16Participants.isEmpty) return;

    await Future.wait(
      failedKind16Participants.entries.map((entry) async {
        final masterPubkey = entry.key;
        final pubkeys = entry.value;

        await _sendReactionToPubkeys(
          pubkeys: pubkeys,
          masterPubkey: masterPubkey,
          eventMessage: eventMessage,
        );
      }),
    );
  }
}

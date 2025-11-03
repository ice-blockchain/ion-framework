// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_message_reaction_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/conversation_pubkeys_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_e2ee_message_status_provider.r.g.dart';

@riverpod
Future<SendE2eeMessageStatusService> sendE2eeMessageStatusService(Ref ref) async {
  final sendE2eeChatMessageService = ref.read(sendE2eeChatMessageServiceProvider);
  final eventSigner = await ref.watch(currentUserIonConnectEventSignerProvider.future);

  return SendE2eeMessageStatusService(
    eventSigner: eventSigner,
    sendE2eeChatMessageService: sendE2eeChatMessageService,
    currentUserMasterPubkey: ref.watch(currentPubkeySelectorProvider) ?? '',
    conversationPubkeysNotifier: ref.watch(conversationPubkeysProvider.notifier),
    conversationMessageDataDaoProvider: ref.watch(conversationMessageDataDaoProvider),
  );
}

class SendE2eeMessageStatusService {
  SendE2eeMessageStatusService({
    required this.eventSigner,
    required this.sendE2eeChatMessageService,
    required this.conversationMessageDataDaoProvider,
    required this.currentUserMasterPubkey,
    required this.conversationPubkeysNotifier,
  });

  final EventSigner? eventSigner;
  final SendE2eeChatMessageService sendE2eeChatMessageService;
  final ConversationMessageDataDao conversationMessageDataDaoProvider;
  final String currentUserMasterPubkey;
  final ConversationPubkeys conversationPubkeysNotifier;

  final allowedStatus = [MessageDeliveryStatus.received, MessageDeliveryStatus.read];

  Future<void> sendMessageStatus({
    required MessageDeliveryStatus status,
    required EventMessage messageEventMessage,
  }) async {
    if (!allowedStatus.contains(status)) {
      return;
    }

    final eventReference =
        EncryptedDirectMessageEntity.fromEventMessage(messageEventMessage)
            .toEventReference();

    if (status == MessageDeliveryStatus.read) {
      final currentStatus = await conversationMessageDataDaoProvider.checkMessageStatus(
        eventReference: eventReference,
        masterPubkey: currentUserMasterPubkey,
      );

      if (currentStatus == MessageDeliveryStatus.read) {
        return;
      }
    }

    final messageReactionData = PrivateMessageReactionEntityData(
      content: status.name,
      reference: eventReference,
      masterPubkey: currentUserMasterPubkey,
    );

    final participantsKeysMap = await conversationPubkeysNotifier
        .fetchUsersKeys(messageEventMessage.participantsMasterPubkeys);

    await Future.wait(
      messageEventMessage.participantsMasterPubkeys.map((masterPubkey) async {
        final pubkeys = participantsKeysMap[masterPubkey];

        if (pubkeys == null) {
          throw UserPubkeyNotFoundException(masterPubkey);
        }

        await Future.wait(
          pubkeys.map((pubkey) async {
            try {
              // If this is read status for the current user mark it as read to
              // make UX more optimistic
              if (masterPubkey == currentUserMasterPubkey && status == MessageDeliveryStatus.read) {
                await conversationMessageDataDaoProvider.addOrUpdateStatus(
                  status: status,
                  pubkey: pubkey,
                  masterPubkey: masterPubkey,
                  messageEventReference: eventReference,
                  updateAllBefore: messageEventMessage.createdAt.toDateTime,
                );
              }

              await sendE2eeChatMessageService.sendWrappedMessage(
                pubkey: pubkey,
                eventSigner: eventSigner!,
                masterPubkey: masterPubkey,
                wrappedKinds: [PrivateMessageReactionEntity.kind.toString()],
                eventMessage: await messageReactionData
                    .toEventMessage(NoPrivateSigner(eventSigner!.publicKey)),
              );
            } catch (e, stackTrace) {
              Logger.error(
                e,
                message: 'Failed to send message status',
                stackTrace: stackTrace,
              );
            }
          }),
        );
      }),
    );
  }
}

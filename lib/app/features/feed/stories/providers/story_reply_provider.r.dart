// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_e2ee_reaction_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/conversation_pubkeys_provider.r.dart';
import 'package:ion/app/features/chat/providers/exist_chat_conversation_id_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/quoted_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/services/uuid/generate_conversation_id.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'story_reply_provider.r.g.dart';

@riverpod
class StoryReply extends _$StoryReply {
  @override
  FutureOr<void> build() {}

  Future<void> sendReply(
    ModifiablePostEntity story, {
    String? replyText,
    String? replyEmoji,
  }) async {
    state = await AsyncValue.guard(() async {
      state = const AsyncLoading();
      final eventSigner = await ref.read(currentUserIonConnectEventSignerProvider.future);

      if (eventSigner == null) {
        throw EventSignerNotFoundException();
      }

      final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);

      if (currentUserMasterPubkey == null) {
        throw UserMasterPubkeyNotFoundException();
      }

      final participantsMasterPubkeys = [
        story.masterPubkey,
        currentUserMasterPubkey,
      ];

      final existingConversationId =
          await ref.read(existChatConversationIdProvider(participantsMasterPubkeys).future);

      final conversationId = existingConversationId ??
          generateConversationId(
            conversationType: ConversationType.direct,
            receiverMasterPubkeys: [story.masterPubkey, currentUserMasterPubkey],
          );

      final storyEventMessage = await story.toEventMessage(story.data);
      final storyAsContent = jsonEncode(storyEventMessage.toJson().last);

      final tags = [
        MasterPubkeyTag(value: currentUserMasterPubkey).toTag(),
        ['k', ModifiablePostEntity.kind.toString()],
        [RelatedPubkey.tagName, eventSigner.publicKey],
        [ConversationIdentifier.tagName, conversationId],
        story.toEventReference().toTag(),
      ];

      final id = EventMessage.calculateEventId(
        tags: tags,
        content: storyAsContent,
        kind: GenericRepostEntity.kind,
        publicKey: eventSigner.publicKey,
        createdAt: DateTime.now().microsecondsSinceEpoch,
      );

      final kind16Rumor = EventMessage(
        id: id,
        tags: tags,
        content: storyAsContent,
        pubkey: eventSigner.publicKey,
        kind: GenericRepostEntity.kind,
        createdAt: storyEventMessage.createdAt,
        sig: null,
      );

      final conversationPubkeysNotifier = ref.read(conversationPubkeysProvider.notifier);

      final participantsKeysMap =
          await conversationPubkeysNotifier.fetchUsersKeys(participantsMasterPubkeys);

      for (final masterPubkey in participantsMasterPubkeys) {
        final pubkeys = participantsKeysMap[masterPubkey];

        if (pubkeys == null) {
          throw UserPubkeyNotFoundException(masterPubkey);
        }

        await ref.read(eventMessageDaoProvider).add(kind16Rumor);
        final entity = GenericRepostEntity.fromEventMessage(kind16Rumor);

        for (final pubkey in pubkeys) {
          try {
            await ref.read(conversationMessageDataDaoProvider).addOrUpdateStatus(
                  pubkey: pubkey,
                  masterPubkey: masterPubkey,
                  status: MessageDeliveryStatus.created,
                  messageEventReference: entity.toEventReference(),
                );

            await ref.read(sendE2eeChatMessageServiceProvider).sendWrappedMessage(
              pubkey: pubkey,
              eventSigner: eventSigner,
              masterPubkey: masterPubkey,
              eventMessage: kind16Rumor,
              wrappedKinds: [
                GenericRepostEntity.kind.toString(),
                ModifiablePostEntity.kind.toString(),
              ],
            );

            await ref.read(conversationMessageDataDaoProvider).addOrUpdateStatus(
                  pubkey: pubkey,
                  masterPubkey: masterPubkey,
                  status: MessageDeliveryStatus.sent,
                  messageEventReference: entity.toEventReference(),
                );
          } catch (e) {
            await ref.read(conversationMessageDataDaoProvider).addOrUpdateStatus(
                  pubkey: pubkey,
                  masterPubkey: masterPubkey,
                  status: MessageDeliveryStatus.failed,
                  messageEventReference: entity.toEventReference(),
                );
          }
        }
      }

      final sentKind14EventMessage = await ref.read(sendE2eeChatMessageServiceProvider).sendMessage(
            content: replyText ?? '',
            conversationId: conversationId,
            participantsMasterPubkeys: participantsMasterPubkeys,
            quotedEvent: QuotedImmutableEvent(
              eventReference: ImmutableEventReference(
                eventId: kind16Rumor.id,
                masterPubkey: kind16Rumor.masterPubkey,
                kind: GenericRepostEntity.kind,
              ),
            ),
          );

      if (replyEmoji != null) {
        await (await ref.read(sendE2eeReactionServiceProvider.future)).sendReaction(
          content: replyEmoji,
          kind14Rumor: sentKind14EventMessage,
        );
      }
    });
  }

  Future<void> resendReply(EventMessage kind30014Rumor) async {
    final kind30014Entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(kind30014Rumor);

    await _resendKind16(kind30014Entity);

    await ref.read(sendE2eeChatMessageServiceProvider).resendMessage(eventMessage: kind30014Rumor);

    final kind7EventReference = await ref
        .read(conversationMessageReactionDaoProvider)
        .getStoryReaction(kind30014Entity.toEventReference());
    final kind7EventMessage = kind7EventReference != null
        ? await ref.read(eventMessageDaoProvider).getByReference(kind7EventReference)
        : null;

    if (kind7EventMessage != null) {
      await (await ref.read(sendE2eeReactionServiceProvider.future))
          .resendReaction(eventMessage: kind7EventMessage);
    }
  }

  Future<void> _resendKind16(ReplaceablePrivateDirectMessageEntity kind30014Entity) async {
    final kind16Rumor = await ref
        .read(eventMessageDaoProvider)
        .getByReference(kind30014Entity.data.quotedEvent!.eventReference);

    final kind16Entity = GenericRepostEntity.fromEventMessage(kind16Rumor);
    final eventSigner = await ref.read(currentUserIonConnectEventSignerProvider.future);

    if (eventSigner == null) {
      throw EventSignerNotFoundException();
    }

    final failedKind16Participants = await ref
        .read(conversationMessageDataDaoProvider)
        .getFailedParticipants(eventReference: kind16Entity.toEventReference());

    if (failedKind16Participants.isNotEmpty) {
      for (final masterPubkey in failedKind16Participants.keys) {
        final pubkeys = failedKind16Participants[masterPubkey];

        if (pubkeys == null) {
          throw UserPubkeyNotFoundException(masterPubkey);
        }

        for (final pubkey in pubkeys) {
          try {
            await ref.read(conversationMessageDataDaoProvider).addOrUpdateStatus(
                  pubkey: pubkey,
                  masterPubkey: masterPubkey,
                  status: MessageDeliveryStatus.created,
                  messageEventReference: kind16Entity.toEventReference(),
                );

            await ref.read(sendE2eeChatMessageServiceProvider).sendWrappedMessage(
              pubkey: pubkey,
              eventSigner: eventSigner,
              masterPubkey: masterPubkey,
              eventMessage: kind16Rumor,
              wrappedKinds: [
                GenericRepostEntity.kind.toString(),
                ModifiablePostEntity.kind.toString(),
              ],
            );

            await ref.read(conversationMessageDataDaoProvider).addOrUpdateStatus(
                  pubkey: pubkey,
                  masterPubkey: masterPubkey,
                  status: MessageDeliveryStatus.sent,
                  messageEventReference: kind16Entity.toEventReference(),
                );
          } catch (e) {
            await ref.read(conversationMessageDataDaoProvider).addOrUpdateStatus(
                  pubkey: pubkey,
                  masterPubkey: masterPubkey,
                  status: MessageDeliveryStatus.failed,
                  messageEventReference: kind16Entity.toEventReference(),
                );
          }
        }
      }
    }
  }
}

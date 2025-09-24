// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/conversation_to_delete.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_message_reaction_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/encrypted_deletion_request_handler.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/conversation_pubkeys_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'e2ee_delete_event_provider.r.g.dart';

@riverpod
class E2eeDeleteReactionNotifier extends _$E2eeDeleteReactionNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> deleteReaction({
    required List<String> participantsMasterPubkeys,
    required ImmutableEventReference reactionEventReference,
  }) async {
    state = await AsyncValue.guard(() async {
      final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);
      final eventSigner = await ref.read(currentUserIonConnectEventSignerProvider.future);

      final conversationPubkeysNotifier = ref.read(conversationPubkeysProvider.notifier);

      if (eventSigner == null) {
        throw EventSignerNotFoundException();
      }

      if (currentUserMasterPubkey == null) {
        throw UserMasterPubkeyNotFoundException();
      }

      final deleteRequest = DeletionRequest(
        events: [
          EventToDelete(
            eventReference:
                reactionEventReference.copyWith(kind: PrivateMessageReactionEntity.kind),
          ),
        ],
      );

      final eventMessage = await deleteRequest.toEventMessage(
        NoPrivateSigner(eventSigner.publicKey),
        masterPubkey: currentUserMasterPubkey,
      );

      final participantsKeysMap =
          await conversationPubkeysNotifier.fetchUsersKeys(participantsMasterPubkeys);

      await Future.wait(
        participantsMasterPubkeys.map((masterPubkey) async {
          final pubkeys = participantsKeysMap[masterPubkey];

          if (pubkeys == null) {
            throw UserPubkeyNotFoundException(masterPubkey);
          }
          for (final pubkey in pubkeys) {
            await ref.read(sendE2eeChatMessageServiceProvider).sendWrappedMessage(
                  eventSigner: eventSigner,
                  masterPubkey: masterPubkey,
                  eventMessage: eventMessage,
                  wrappedKinds: [DeletionRequestEntity.kind.toString()],
                  pubkey: pubkey,
                );
          }
        }),
      );
    });
  }
}

@riverpod
Future<void> e2eeDeleteMessage(
  Ref ref, {
  required List<EventMessage> messageEvents,
  bool forEveryone = false,
}) async {
  await _deleteMessages(
    ref: ref,
    forEveryone: forEveryone,
    messageEvents: messageEvents,
  );
}

@riverpod
class E2eeDeleteMessageNotifier extends _$E2eeDeleteMessageNotifier {
  @override
  FutureOr<void> build({required EventMessage eventMessage}) {}

  Future<void> deleteMessage({
    bool forEveryone = false,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () async {
        await _deleteMessages(
          ref: ref,
          messageEvents: [eventMessage],
          forEveryone: forEveryone,
        );
      },
    );
  }
}

@riverpod
Future<void> e2eeDeleteConversation(
  Ref ref, {
  required List<String> conversationIds,
  bool forEveryone = false,
}) async {
  await _deleteConversations(
    ref: ref,
    forEveryone: forEveryone,
    conversationIds: conversationIds,
  );
}

@riverpod
class E2eeDeleteAccount extends _$E2eeDeleteAccount {
  @override
  FutureOr<void> build() {}

  Future<void> deleteAccountConversations() async {
    // Send request to delete all conversations
    final conversationDao = ref.read(conversationDaoProvider);
    final conversationIds = await conversationDao.getAllConversationsIds();
    await _deleteConversations(ref: ref, conversationIds: conversationIds, forEveryone: false);
  }
}

Future<void> _deleteMessages({
  required Ref ref,
  required bool forEveryone,
  required List<EventMessage> messageEvents,
}) async {
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  final eventSigner = await ref.watch(currentUserIonConnectEventSignerProvider.future);

  final conversationPubkeysNotifier = ref.watch(conversationPubkeysProvider.notifier);

  if (eventSigner == null) {
    throw EventSignerNotFoundException();
  }

  if (currentUserMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final participantsMasterPubkeys =
      forEveryone ? messageEvents.first.participantsMasterPubkeys : [currentUserMasterPubkey];

  final deleteRequest = DeletionRequest(
    events: messageEvents
        .map((event) {
          final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(event);

          if (entity.data.quotedEvent != null) {
            return [
              EventToDelete(
                eventReference: entity.data.quotedEvent!.eventReference
                    .copyWith(kind: GenericRepostEntity.kind),
              ),
              EventToDelete(eventReference: entity.toEventReference()),
            ];
          }

          return [EventToDelete(eventReference: entity.toEventReference())];
        })
        .expand((element) => element)
        .toList(),
  );

  final eventMessage = await deleteRequest.toEventMessage(
    NoPrivateSigner(eventSigner.publicKey),
    masterPubkey: currentUserMasterPubkey,
  );

  // Mark message as deleted in the database
  final deletionHandler = await ref.read(encryptedDeletionRequestHandlerProvider.future);
  await deletionHandler?.deleteConversationMessages(eventMessage);

  try {
    final participantsKeysMap =
        await conversationPubkeysNotifier.fetchUsersKeys(participantsMasterPubkeys);

    await Future.wait(
      participantsMasterPubkeys.map((masterPubkey) async {
        final pubkeys = participantsKeysMap[masterPubkey];

        if (pubkeys == null) {
          throw UserPubkeyNotFoundException(masterPubkey);
        }

        await Future.wait(
          pubkeys.map((pubkey) async {
            await ref.read(sendE2eeChatMessageServiceProvider).sendWrappedMessage(
                  eventSigner: eventSigner,
                  masterPubkey: masterPubkey,
                  eventMessage: eventMessage,
                  wrappedKinds: [DeletionRequestEntity.kind.toString()],
                  pubkey: pubkey,
                );
          }),
        );
      }),
    );
  } catch (e) {
    // Revert the deletion in the database if sending fails
    final deletionHandler = await ref.read(encryptedDeletionRequestHandlerProvider.future);
    unawaited(deletionHandler?.revertDeletedConversationMessages(eventMessage));
  }
}

Future<void> _deleteConversations({
  required Ref ref,
  required bool forEveryone,
  required List<String> conversationIds,
}) async {
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  final eventSigner = await ref.watch(currentUserIonConnectEventSignerProvider.future);

  final conversationPubkeysNotifier = ref.watch(conversationPubkeysProvider.notifier);

  if (currentUserMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  if (eventSigner == null) {
    throw EventSignerNotFoundException();
  }

  final deleteRequest =
      DeletionRequest(events: conversationIds.map(ConversationToDelete.new).toList());

  final eventMessage = await deleteRequest.toEventMessage(
    NoPrivateSigner(eventSigner.publicKey),
    masterPubkey: currentUserMasterPubkey,
  );

  final conversationDao = ref.watch(conversationDaoProvider);

  // Mark conversations as hidden in the database
  // This is a soft delete, so we hide them instead of deleting
  await conversationDao.hideConversations(conversationIds);

  final failedConversations = <String>[];

  await Future.wait(
    conversationIds.map((conversationId) async {
      try {
        final participantsMasterPubkeys = forEveryone
            ? await conversationDao.getConversationParticipants(conversationId)
            : [currentUserMasterPubkey];

        final participantsKeysMap =
            await conversationPubkeysNotifier.fetchUsersKeys(participantsMasterPubkeys);

        await Future.wait(
          participantsMasterPubkeys.map((masterPubkey) async {
            final pubkeys = participantsKeysMap[masterPubkey];
            if (pubkeys == null || pubkeys.isEmpty) {
              throw UserPubkeyNotFoundException(masterPubkey);
            }

            await Future.wait(
              pubkeys.map(
                (pubkey) => ref.read(sendE2eeChatMessageServiceProvider).sendWrappedMessage(
                  pubkey: pubkey,
                  eventSigner: eventSigner,
                  masterPubkey: masterPubkey,
                  eventMessage: eventMessage,
                  wrappedKinds: [DeletionRequestEntity.kind.toString()],
                ),
              ),
            );
          }),
        );
      } catch (_) {
        failedConversations.add(conversationId);
      }
    }),
  );

  await conversationDao.unhideConversations(failedConversations);
}

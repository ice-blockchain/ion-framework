// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/providers/conversation_pubkeys_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'funds_request_delete_notifier.r.g.dart';

@riverpod
class FundsRequestDeleteNotifier extends _$FundsRequestDeleteNotifier {
  @override
  FutureOr<void> build({required EventMessage eventMessage}) {}

  Future<void> deleteFundsRequest() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _deleteFundsRequest(ref: ref, eventMessage: eventMessage);
    });
  }

  Future<void> _deleteFundsRequest({
    required Ref ref,
    required EventMessage eventMessage,
  }) async {
    // Extract event reference from chat message content
    final eventReference = EventReference.fromEncoded(eventMessage.content);

    if (eventReference is! ImmutableEventReference) {
      throw Exception('Invalid event reference type');
    }

    if (eventReference.kind != FundsRequestEntity.kind) {
      throw Exception('Event is not a FundsRequest');
    }

    final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);
    final eventSigner = await ref.read(currentUserIonConnectEventSignerProvider.future);
    final conversationPubkeysNotifier = ref.read(conversationPubkeysProvider.notifier);

    if (eventSigner == null) {
      throw EventSignerNotFoundException();
    }

    if (currentUserMasterPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    // Create deletion request for the FundsRequest event
    final deletionRequest = DeletionRequest(
      events: [
        EventToDelete(
          eventReference: ImmutableEventReference(
            eventId: eventReference.eventId,
            masterPubkey: eventReference.masterPubkey,
            kind: FundsRequestEntity.kind,
          ),
        ),
      ],
    );

    final deletionEvent = await deletionRequest.toEventMessage(
      NoPrivateSigner(eventSigner.publicKey),
      masterPubkey: currentUserMasterPubkey,
    );

    // Get all participants
    final participantsMasterPubkeys = eventMessage.participantsMasterPubkeys;
    final participantsKeysMap =
        await conversationPubkeysNotifier.fetchUsersKeys(participantsMasterPubkeys);

    // Send wrapped deletion event to all participants
    for (final masterPubkey in participantsMasterPubkeys) {
      final pubkeys = participantsKeysMap[masterPubkey];
      if (pubkeys == null) continue;

      final sendOperationFutures = pubkeys.map(
        (pubkey) => ref.read(sendE2eeChatMessageServiceProvider).sendWrappedMessage(
              eventSigner: eventSigner,
              masterPubkey: masterPubkey,
              eventMessage: deletionEvent,
              wrappedKinds: [DeletionRequestEntity.kind.toString()],
              pubkey: pubkey,
            ),
      );

      await Future.wait(sendOperationFutures);
    }
  }
}

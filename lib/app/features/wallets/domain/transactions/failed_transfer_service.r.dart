// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/providers/conversation_pubkeys_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'failed_transfer_service.r.g.dart';

@Riverpod(keepAlive: true)
Future<FailedTransferService> failedTransferService(Ref ref) async {
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  final eventSigner = await ref.watch(currentUserIonConnectEventSignerProvider.future);
  final sendE2eeChatMessageService = ref.watch(sendE2eeChatMessageServiceProvider);
  final conversationPubkeysNotifier = ref.watch(conversationPubkeysProvider.notifier);

  return FailedTransferService(
    currentUserMasterPubkey: currentUserMasterPubkey,
    eventSigner: eventSigner,
    sendE2eeChatMessageService: sendE2eeChatMessageService,
    conversationPubkeysNotifier: conversationPubkeysNotifier,
  );
}

class FailedTransferService {
  const FailedTransferService({
    required this.currentUserMasterPubkey,
    required this.eventSigner,
    required this.sendE2eeChatMessageService,
    required this.conversationPubkeysNotifier,
  });

  final String? currentUserMasterPubkey;
  final EventSigner? eventSigner;
  final SendE2eeChatMessageService sendE2eeChatMessageService;
  final ConversationPubkeys conversationPubkeysNotifier;

  Future<void> markTransferAsFailed(TransactionData transaction) async {
    try {
      if (transaction.eventId == null) {
        Logger.log('Transaction ${transaction.txHash} has no eventId, skipping deletion');
        return;
      }

      if (transaction.userPubkey == null) {
        Logger.log('Transaction ${transaction.txHash} has no userPubkey, skipping deletion');
        return;
      }

      await _sendDeleteRequest(transaction);
    } catch (e, stack) {
      Logger.error(
        e,
        stackTrace: stack,
        message: 'Failed to send deletion request for transfer ${transaction.txHash}',
      );
    }
  }

  Future<void> _sendDeleteRequest(TransactionData transaction) async {
    final signer = eventSigner;
    final masterPubkey = currentUserMasterPubkey;

    if (signer == null) {
      throw EventSignerNotFoundException();
    }

    if (masterPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    // Create deletion request for the WalletAssetEntity event
    final deletionRequest = DeletionRequest(
      events: [
        EventToDelete(
          eventReference: ImmutableEventReference(
            eventId: transaction.eventId!,
            masterPubkey: masterPubkey,
            kind: WalletAssetEntity.kind,
          ),
        ),
      ],
    );

    final deletionEvent = await deletionRequest.toEventMessage(
      NoPrivateSigner(signer.publicKey),
      masterPubkey: masterPubkey,
    );

    // Get participants (sender and receiver)
    final participantsMasterPubkeys = <String>[
      masterPubkey,
      if (transaction.userPubkey != null && transaction.userPubkey != masterPubkey)
        transaction.userPubkey!,
    ];

    final participantsKeysMap =
        await conversationPubkeysNotifier.fetchUsersKeys(participantsMasterPubkeys);

    Logger.log(
      'Sending delete request to ${participantsMasterPubkeys.length} participants',
    );

    // Send wrapped deletion event to all participants
    for (final masterPubkey in participantsMasterPubkeys) {
      final pubkeys = participantsKeysMap[masterPubkey];
      if (pubkeys == null) {
        continue;
      }

      final sendOperationFutures = pubkeys.map(
        (pubkey) => sendE2eeChatMessageService.sendWrappedMessage(
          eventSigner: signer,
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

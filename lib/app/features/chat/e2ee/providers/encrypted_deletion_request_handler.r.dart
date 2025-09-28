// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_message_reaction_data.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_encrypted_event_message_handler.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/user_profile/providers/user_profile_sync_provider.r.dart';
import 'package:ion/app/features/wallets/data/repository/request_assets_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'encrypted_deletion_request_handler.r.g.dart';

class EncryptedDeletionRequestHandler extends GlobalSubscriptionEncryptedEventMessageHandler {
  EncryptedDeletionRequestHandler(
    this.conversationMessageDao,
    this.conversationMessageReactionDao,
    this.conversationDao,
    this.eventMessageDao,
    this.env,
    this.masterPubkey,
    this.eventSigner,
    this.userProfileSyncProvider,
    this.requestAssetsRepository,
    this.transactionsRepository,
  );

  final ConversationMessageDao conversationMessageDao;
  final ConversationMessageReactionDao conversationMessageReactionDao;
  final ConversationDao conversationDao;
  final EventMessageDao eventMessageDao;
  final UserProfileSync userProfileSyncProvider;
  final RequestAssetsRepository requestAssetsRepository;
  final TransactionsRepository transactionsRepository;

  final Env env;
  final String masterPubkey;
  final EventSigner eventSigner;

  @override
  bool canHandle({
    required IonConnectGiftWrapEntity entity,
  }) {
    return entity.data.kinds.containsDeep([DeletionRequestEntity.kind.toString()]);
  }

  @override
  Future<EventReference> handle(EventMessage rumor) async {
    final deletionRequest = DeletionRequestEntity.fromEventMessage(rumor);
    final eventsToDelete = deletionRequest.data.events.whereType<EventToDelete>().toList();

    unawaited(_deleteConversation(rumor));
    unawaited(deleteConversationMessages(eventsToDelete));
    unawaited(_deleteMessageReaction(rumor));
    unawaited(userProfileSyncProvider.syncUserProfile(masterPubkeys: {rumor.masterPubkey}));
    unawaited(_deleteFundsRequest(rumor));
    unawaited(_deleteWalletAsset(rumor));

    return deletionRequest.toEventReference();
  }

  Future<void> _deleteConversation(EventMessage rumor) async {
    final deleteConversationIds = rumor.tags
        .where((tags) => tags[0] == ConversationIdentifier.tagName)
        .map((tag) => tag.elementAtOrNull(1))
        .nonNulls
        .toList();

    if (deleteConversationIds.isNotEmpty) {
      await eventMessageDao.add(rumor);
      await conversationDao.removeConversations(
        deleteRequest: rumor,
        conversationIds: deleteConversationIds,
        eventMessageDao: eventMessageDao,
      );
    }
  }

  Future<void> _deleteMessageReaction(EventMessage rumor) async {
    final deletionRequest = DeletionRequest.fromEventMessage(rumor);

    final reactionsToDelete = deletionRequest.events
        .whereType<EventToDelete>()
        .where(
          (event) =>
              event.eventReference is ImmutableEventReference &&
              event.eventReference.kind == PrivateMessageReactionEntity.kind,
        )
        .map((event) => event.eventReference as ImmutableEventReference)
        .toList();

    if (reactionsToDelete.isEmpty) return;

    await Future.wait(
      reactionsToDelete.map((reactionEventReference) async {
        await conversationMessageReactionDao.remove(
          reactionEventReference: reactionEventReference,
        );
      }),
    );
  }

  Future<void> deleteConversationMessages(List<EventToDelete> eventsToDelete) async {
    if (eventsToDelete.isEmpty) return;

    for (final event in eventsToDelete) {
      final eventReference = event.eventReference;
      if (eventReference is ReplaceableEventReference) {
        await conversationMessageDao.removeMessages(
          env: env,
          masterPubkey: masterPubkey,
          eventReferences: [eventReference],
          eventSignerPubkey: eventSigner.publicKey,
        );
      } else if (eventReference is ImmutableEventReference) {
        await conversationMessageDao.removeMessages(
          env: env,
          masterPubkey: masterPubkey,
          eventReferences: [eventReference],
          eventSignerPubkey: eventSigner.publicKey,
        );
        await conversationMessageReactionDao.remove(reactionEventReference: eventReference);
      }
    }
  }

  Future<void> revertDeletedConversationMessages(EventMessage rumor) async {
    final eventsToDelete =
        DeletionRequest.fromEventMessage(rumor).events.whereType<EventToDelete>().toList();

    if (eventsToDelete.isEmpty) return;

    for (final event in eventsToDelete) {
      final eventReference = event.eventReference;
      if (eventReference is ReplaceableEventReference) {
        await conversationMessageDao.revertDeletedMessages(
          env: env,
          masterPubkey: masterPubkey,
          eventReferences: [eventReference],
          eventSignerPubkey: eventSigner.publicKey,
        );
      } else if (eventReference is ImmutableEventReference) {
        await conversationMessageDao.revertDeletedMessages(
          env: env,
          masterPubkey: masterPubkey,
          eventReferences: [eventReference],
          eventSignerPubkey: eventSigner.publicKey,
        );

        await conversationMessageReactionDao.revertDeletedReaction(
          reactionEventReference: eventReference,
        );
      }
    }
  }

  Future<void> _deleteFundsRequest(EventMessage rumor) async {
    final deletionRequest = DeletionRequest.fromEventMessage(rumor);

    final eventsToDelete = deletionRequest.events.whereType<EventToDelete>().toList();

    for (final event in eventsToDelete) {
      final eventReference = event.eventReference;

      final isFundsRequest = eventReference is ImmutableEventReference &&
          eventReference.kind == FundsRequestEntity.kind;

      if (isFundsRequest) {
        await requestAssetsRepository.markRequestAsDeleted(eventReference.eventId);
      }
    }
  }

  Future<void> _deleteWalletAsset(EventMessage rumor) async {
    final deletionRequest = DeletionRequest.fromEventMessage(rumor);

    final eventsToDelete = deletionRequest.events.whereType<EventToDelete>().toList();

    final walletAssetDeletions = eventsToDelete
        .where(
          (event) =>
              event.eventReference is ImmutableEventReference &&
              event.eventReference.kind == WalletAssetEntity.kind,
        )
        .map((event) => event.eventReference as ImmutableEventReference)
        .toList();

    if (walletAssetDeletions.isNotEmpty) {
      await Future.wait(
        walletAssetDeletions.map((eventReference) async {
          final transaction = await transactionsRepository.getTransactions(
            eventIds: [eventReference.eventId],
            limit: 1,
          ).then((result) => result.firstOrNull);

          if (transaction != null) {
            await transactionsRepository.updateTransaction(
              txHash: transaction.txHash,
              walletViewId: transaction.walletViewId,
              status: TransactionStatus.failed.toJson(),
            );
          }
        }),
      );
    }
  }
}

@riverpod
Future<EncryptedDeletionRequestHandler?> encryptedDeletionRequestHandler(Ref ref) async {
  final eventSigner = await ref.watch(currentUserIonConnectEventSignerProvider.future);
  final masterPubkey = ref.watch(currentPubkeySelectorProvider);
  if (eventSigner == null || masterPubkey == null) {
    return null;
  }

  return EncryptedDeletionRequestHandler(
    ref.watch(conversationMessageDaoProvider),
    ref.watch(conversationMessageReactionDaoProvider),
    ref.watch(conversationDaoProvider),
    ref.watch(eventMessageDaoProvider),
    ref.watch(envProvider.notifier),
    masterPubkey,
    eventSigner,
    ref.watch(userProfileSyncProvider.notifier),
    ref.watch(requestAssetsRepositoryProvider),
    await ref.watch(transactionsRepositoryProvider.future),
  );
}

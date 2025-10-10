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
import 'package:ion/app/features/wallets/data/repository/request_assets_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/services/local_notifications/local_notifications.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'encrypted_deletion_request_handler.r.g.dart';

class EncryptedDeletionRequestHandler extends GlobalSubscriptionEncryptedEventMessageHandler {
  EncryptedDeletionRequestHandler({
    required this.env,
    required this.eventSigner,
    required this.masterPubkey,
    required this.conversationDao,
    required this.eventMessageDao,
    required this.transactionsRepository,
    required this.requestAssetsRepository,
    required this.conversationMessageDao,
    required this.localNotificationsService,
    required this.conversationMessageReactionDao,
  });

  final Env env;
  final String masterPubkey;
  final EventSigner eventSigner;
  final EventMessageDao eventMessageDao;
  final ConversationDao conversationDao;
  final ConversationMessageDao conversationMessageDao;
  final TransactionsRepository transactionsRepository;
  final RequestAssetsRepository requestAssetsRepository;
  final LocalNotificationsService localNotificationsService;
  final ConversationMessageReactionDao conversationMessageReactionDao;

  @override
  bool canHandle({required IonConnectGiftWrapEntity entity}) =>
      entity.data.kinds.containsDeep([DeletionRequestEntity.kind.toString()]);

  @override
  Future<EventReference> handle(EventMessage rumor) async {
    await eventMessageDao.add(rumor);
    final deletionRequest = DeletionRequestEntity.fromEventMessage(rumor);

    unawaited(_removeMessageReactionFromDatabase(rumor));
    unawaited(_removeMessagesFromDatabase(rumor));
    unawaited(_removeConversationsFromDatabase(rumor));
    unawaited(_deleteFundsRequest(rumor));
    unawaited(_deleteWalletAsset(rumor));

    return deletionRequest.toEventReference();
  }

  Future<void> _removeConversationsFromDatabase(EventMessage rumor) async {
    final conversationIds = rumor.tags
        .where((tags) => tags[0] == ConversationIdentifier.tagName)
        .map((tag) => tag.elementAtOrNull(1))
        .nonNulls
        .toList();

    if (conversationIds.isNotEmpty) {
      unawaited(localNotificationsService.cancelByGroupKeys(conversationIds));

      await conversationDao.removeConversationsFromDatabase(
        startingFrom: rumor.createdAt,
        conversationIds: conversationIds,
      );
    }
  }

  Future<void> _removeMessagesFromDatabase(EventMessage rumor) async {
    final eventsToDelete =
        DeletionRequest.fromEventMessage(rumor).events.whereType<EventToDelete>().toList();

    final messageEventReferences = eventsToDelete
        .where((event) => event.eventReference is ReplaceableEventReference)
        .map((event) => event.eventReference)
        .toList();

    if (messageEventReferences.isEmpty) return;

    await conversationMessageDao.removeMessagesFromDatabase(messageEventReferences);
  }

  Future<void> _removeMessageReactionFromDatabase(EventMessage rumor) async {
    final eventsToDelete =
        DeletionRequest.fromEventMessage(rumor).events.whereType<EventToDelete>().toList();

    final reactionsEventReferences = eventsToDelete
        .where(
          (event) =>
              event.eventReference is ImmutableEventReference &&
              event.eventReference.kind == PrivateMessageReactionEntity.kind,
        )
        .map((event) => event.eventReference as ImmutableEventReference)
        .toList();

    if (reactionsEventReferences.isEmpty) return;

    await conversationMessageReactionDao.removeReactionsFromDatabase(reactionsEventReferences);
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
    eventSigner: eventSigner,
    masterPubkey: masterPubkey,
    env: ref.watch(envProvider.notifier),
    conversationDao: ref.watch(conversationDaoProvider),
    eventMessageDao: ref.watch(eventMessageDaoProvider),
    conversationMessageDao: ref.watch(conversationMessageDaoProvider),
    requestAssetsRepository: ref.watch(requestAssetsRepositoryProvider),
    transactionsRepository: await ref.watch(transactionsRepositoryProvider.future),
    conversationMessageReactionDao: ref.watch(conversationMessageReactionDaoProvider),
    localNotificationsService: await ref.watch(localNotificationsServiceProvider.future),
  );
}

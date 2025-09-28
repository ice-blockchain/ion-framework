// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_encrypted_event_message_handler.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/wallets/data/repository/request_assets_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/wallet_views/wallet_views_service.r.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_asset_request_validator.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_asset_handler.r.g.dart';

class WalletAssetHandler extends GlobalSubscriptionEncryptedEventMessageHandler {
  WalletAssetHandler(
    this.currentPubkey,
    this.walletViewsService,
    this.transactionsRepository,
    this.requestAssetsRepository,
    this.requestValidator,
  );

  final String currentPubkey;
  final WalletViewsService walletViewsService;
  final TransactionsRepository transactionsRepository;
  final RequestAssetsRepository requestAssetsRepository;
  final WalletAssetRequestValidator requestValidator;

  @override
  bool canHandle({required IonConnectGiftWrapEntity entity}) {
    return entity.data.kinds.containsDeep([WalletAssetEntity.kind.toString()]);
  }

  @override
  Future<EventReference> handle(EventMessage rumor) async {
    final message = WalletAssetEntity.fromEventMessage(rumor);

    // Since the current user is the recipient,
    // we need to replace his pubkey inside the asset
    // with the sender's pubkey to maintain accurate information about the sender.
    final adjustedMessage = message.data.pubkey == currentPubkey
        ? message.copyWith(
            data: message.data.copyWith(pubkey: message.masterPubkey),
          )
        : message;

    final requestJson = adjustedMessage.data.request;
    if (requestJson != null) {
      // Validate the request according to ICIP-6000 before processing
      final isValidRequest = await requestValidator.validateRequest(
        walletAssetEntity: adjustedMessage,
        requestJson: requestJson,
      );

      if (!isValidRequest) {
        Logger.error(
          'Request validation failed for 1756 event: ${adjustedMessage.id}. Ignoring transaction.',
        );
      }
    }

    final walletViews = walletViewsService.lastEmitted.isNotEmpty
        ? walletViewsService.lastEmitted
        : await walletViewsService.walletViews.first;
    await transactionsRepository.saveEntities([adjustedMessage], walletViews);

    if (requestJson != null) {
      try {
        final decodedJson = jsonDecode(requestJson) as Map;

        final requestId = decodedJson['id'] as String;
        final txHash = adjustedMessage.data.content.txHash;
        await requestAssetsRepository.markRequestAsPaid(requestId, txHash);
      } catch (e) {
        Logger.error('Failed to parse request JSON: $e');
      }
    }

    return message.toEventReference();
  }
}

@riverpod
Future<WalletAssetHandler?> walletAssetHandler(Ref ref) async {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);
  final walletViewsService = await ref.watch(walletViewsServiceProvider.future);
  final transactionsRepository = await ref.watch(transactionsRepositoryProvider.future);
  final requestAssetsRepository = ref.watch(requestAssetsRepositoryProvider);
  final requestValidator = ref.watch(walletAssetRequestValidatorProvider);

  if (currentPubkey == null) {
    return null;
  }

  return WalletAssetHandler(
    currentPubkey,
    walletViewsService,
    transactionsRepository,
    requestAssetsRepository,
    requestValidator,
  );
}

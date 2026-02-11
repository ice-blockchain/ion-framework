// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/bsc_network_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/fat_address_data_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_operation_protected_accounts_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_community_token_controller_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/services/token_import_service.r.dart';
import 'package:ion/app/features/tokenized_communities/services/token_transaction_service.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/master_pubkey_resolver.dart';
import 'package:ion/app/features/tokenized_communities/utils/payment_token_address_resolver.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_data_sync_coordinator_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:ion/app/utils/crypto.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_trade_notifier_provider.r.g.dart';

typedef CommunityTokenTradeNotifierParams = ({
  String externalAddress,
  ExternalAddressType externalAddressType,
  EventReference? eventReference,
});

//TODO cleanup extensive logs after swap becomes stable
@riverpod
class CommunityTokenTradeNotifier extends _$CommunityTokenTradeNotifier {
  static const _firstBuyMetadataSentKey = 'community_token_first_buy';
  static const _broadcastedStatus = 'broadcasted';

  static const _syncWalletDataDelay = Duration(seconds: 3);

  @override
  FutureOr<String?> build(CommunityTokenTradeNotifierParams params) => null;

  Future<void> buy(UserActionSignerNew signer) async {
    Logger.info(
      '[CommunityTokenTradeNotifier] buy() called | externalAddress=${params.externalAddress} | isLoading=${state.isLoading}',
    );

    if (state.isLoading) {
      Logger.warning('[CommunityTokenTradeNotifier] Already loading, skipping buy()');
      return;
    }

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      Logger.info('[CommunityTokenTradeNotifier] Starting buy operation');

      // Check if this account is protected from token operations
      Logger.info('[CommunityTokenTradeNotifier] Step 1: Checking account protection');
      final protectedAccountsService = ref.read(tokenOperationProtectedAccountsServiceProvider);
      final isProtected = params.eventReference != null
          ? protectedAccountsService.isProtectedAccountEvent(params.eventReference!)
          : protectedAccountsService.isProtectedAccountFromExternalAddress(
              params.externalAddress,
            );
      if (isProtected) {
        Logger.warning('[CommunityTokenTradeNotifier] Account is protected');
        throw const TokenOperationProtectedException();
      }
      Logger.info('[CommunityTokenTradeNotifier] Step 2: Reading form state');
      final formState = ref.read(tradeCommunityTokenControllerProvider(params));

      final token = formState.selectedPaymentToken;
      final wallet = formState.targetWallet;
      final amount = formState.amount;

      Logger.info(
        '[CommunityTokenTradeNotifier] Form state | token=${token?.abbreviation} | wallet=${wallet?.id} | amount=$amount',
      );

      if (token == null || wallet == null || amount <= 0) {
        Logger.error(
          '[CommunityTokenTradeNotifier] Invalid form state | token=$token | wallet=$wallet | amount=$amount',
        );
        throw StateError('Invalid form state: token, wallet, or amount is missing');
      }

      if (wallet.address == null) {
        Logger.error(
          '[CommunityTokenTradeNotifier] Wallet address is missing for wallet ${wallet.id} on network ${wallet.network}',
        );
        throw Exception('Wallet address is missing');
      }

      Logger.info('[CommunityTokenTradeNotifier] Step 3: Converting amount to blockchain units');
      final amountIn = toBlockchainUnits(amount, token.decimals);
      Logger.info(
        '[CommunityTokenTradeNotifier] Amount converted | amount=$amount | amountIn=$amountIn | decimals=${token.decimals}',
      );

      Logger.info('[CommunityTokenTradeNotifier] Step 4: Getting trade service');
      final service = await ref.read(tradeCommunityTokenServiceProvider.future);
      Logger.info('[CommunityTokenTradeNotifier] Trade service obtained');

      final expectedPricing = formState.quotePricing;

      if (formState.isQuoting || expectedPricing == null) {
        Logger.error(
          '[CommunityTokenTradeNotifier] Quote not ready | isQuoting=${formState.isQuoting} | expectedPricing=$expectedPricing',
        );
        throw StateError('Quote is not ready yet');
      }

      await _ensurePricingValidForBuy(
        expectedPricing: expectedPricing,
        externalAddress: params.externalAddress,
        externalAddressType: params.externalAddressType,
      );

      Logger.info('[CommunityTokenTradeNotifier] Step 5: Sending first buy metadata if needed');
      await _sendFirstBuyMetadataIfNeeded();

      Logger.info('[CommunityTokenTradeNotifier] Step 6: Getting token info and fat address data');
      final existingTokenInfo =
          ref.read(tokenMarketInfoProvider(params.externalAddress)).valueOrNull;
      final existingTokenAddress = existingTokenInfo?.addresses.blockchain;
      Logger.info(
        '[CommunityTokenTradeNotifier] Token info | existingTokenAddress=$existingTokenAddress',
      );

      // Create fat address data for token first buy
      final fatAddressData = (existingTokenAddress != null && existingTokenAddress.isNotEmpty)
          ? null
          : await ref.read(
              fatAddressDataProvider(
                externalAddress: params.externalAddress,
                externalAddressType: params.externalAddressType,
                eventReference: params.eventReference,
                suggestedDetails: formState.suggestedDetails,
                pricing: expectedPricing,
              ).future,
            );

      if (params.externalAddressType.isContentToken &&
          fatAddressData != null &&
          ((formState.suggestedDetails?.name.isEmpty ?? true) ||
              (formState.suggestedDetails?.ticker.isEmpty ?? true))) {
        Logger.error(
          '[CommunityTokenTradeNotifier] Missing AI generated suggested details | suggestedDetails=${formState.suggestedDetails}',
        );
        throw Exception(
          'Missing AI generated suggested details for content token first buy, externalAddress=${params.externalAddress}',
        );
      }

      Logger.info(
        '[CommunityTokenTradeNotifier] Fat address data | hasFatAddressData=${fatAddressData != null}',
      );

      Logger.info('[CommunityTokenTradeNotifier] Step 7: Calling buyCommunityToken service');
      Logger.info(
        '[CommunityTokenTradeNotifier] Buy parameters | '
        'externalAddress=${params.externalAddress} | '
        'externalAddressType=${params.externalAddressType} | '
        'amountIn=$amountIn | '
        'walletId=${wallet.id} | '
        'walletAddress=${wallet.address} | '
        'baseTokenAddress=${token.contractAddress} | '
        'slippage=${formState.slippage}',
      );

      final response = await service.buyCommunityToken(
        externalAddress: params.externalAddress,
        externalAddressType: params.externalAddressType,
        amountIn: amountIn,
        walletId: wallet.id,
        walletAddress: wallet.address!,
        walletNetwork: wallet.network,
        baseTokenAddress: resolvePaymentTokenAddress(token),
        baseTokenTicker: token.abbreviation,
        tokenDecimals: token.decimals,
        expectedPricing: expectedPricing,
        fatAddressData: fatAddressData,
        userActionSigner: signer,
        shouldSendEvents: formState.shouldSendEvents,
        slippagePercent: formState.slippage,
      );

      Logger.info(
        '[CommunityTokenTradeNotifier] buyCommunityToken response received | response=$response',
      );

      Logger.info('[CommunityTokenTradeNotifier] Step 8: Validating transaction hash');
      final txHash = _requireBroadcastedTxHash(response);
      Logger.info('[CommunityTokenTradeNotifier] Transaction hash validated | txHash=$txHash');

      Logger.info('[CommunityTokenTradeNotifier] Step 9: Importing token and saving transaction');
      try {
        final tokenImportService = ref.read(tokenImportServiceProvider);
        Logger.info('[CommunityTokenTradeNotifier] Importing token if needed');
        await tokenImportService.importTokenIfNeeded(
          externalAddress: params.externalAddress,
          existingTokenAddress: existingTokenAddress,
          communityTokenCoinsGroup: formState.communityTokenCoinsGroup,
        );
        Logger.info('[CommunityTokenTradeNotifier] Token import completed');

        final tokenTransactionService = ref.read(tokenTransactionServiceProvider);
        Logger.info('[CommunityTokenTradeNotifier] Saving pending transaction');
        await tokenTransactionService.savePendingTransaction(
          externalAddress: params.externalAddress,
          transactionId: response['id']?.toString(),
          txHash: txHash,
          wallet: wallet,
          paymentToken: token,
          amount: amount,
          expectedPricing: expectedPricing,
          paymentCoinsGroup: formState.paymentCoinsGroup,
        );
        Logger.info('[CommunityTokenTradeNotifier] Transaction saved');
      } catch (error, stackTrace) {
        Logger.error(
          error,
          stackTrace: stackTrace,
          message: '[CommunityTokenTradeNotifier] Failed to import token or save transaction',
        );
      }

      Logger.info('[CommunityTokenTradeNotifier] Step 10: Scheduling wallet data sync');
      unawaited(
        Future.delayed(
          _syncWalletDataDelay,
          () => ref.read(walletDataSyncCoordinatorProvider).syncWalletData(),
        ),
      );

      Logger.info(
        '[CommunityTokenTradeNotifier] Buy operation completed successfully | txHash=$txHash',
      );
      return txHash;
    });
  }

  Future<void> sell(UserActionSignerNew signer) async {
    Logger.info(
      '[CommunityTokenTradeNotifier] sell() called | externalAddress=${params.externalAddress} | isLoading=${state.isLoading}',
    );

    if (state.isLoading) {
      Logger.warning('[CommunityTokenTradeNotifier] Already loading, skipping sell()');
      return;
    }

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      Logger.info('[CommunityTokenTradeNotifier] Starting sell operation');

      // Check if this account is protected from token operations
      Logger.info('[CommunityTokenTradeNotifier] Step 1: Checking account protection');
      final protectedAccountsService = ref.read(tokenOperationProtectedAccountsServiceProvider);
      final isProtected = params.eventReference != null
          ? protectedAccountsService.isProtectedAccountEvent(params.eventReference!)
          : protectedAccountsService.isProtectedAccountFromExternalAddress(
              params.externalAddress,
            );
      if (isProtected) {
        Logger.warning('[CommunityTokenTradeNotifier] Account is protected');
        throw const TokenOperationProtectedException();
      }
      Logger.info('[CommunityTokenTradeNotifier] Account protection check passed');

      Logger.info('[CommunityTokenTradeNotifier] Step 2: Reading form state');
      final formState = ref.read(tradeCommunityTokenControllerProvider(params));

      final token = formState.selectedPaymentToken;
      final wallet = formState.targetWallet;
      final amount = formState.amount;

      Logger.info(
        '[CommunityTokenTradeNotifier] Form state | token=${token?.abbreviation} | wallet=${wallet?.id} | amount=$amount',
      );

      if (token == null || wallet == null || amount <= 0) {
        Logger.error(
          '[CommunityTokenTradeNotifier] Invalid form state | token=$token | wallet=$wallet | amount=$amount',
        );
        throw StateError('Invalid form state: token, wallet, or amount is missing');
      }

      if (wallet.address == null) {
        Logger.error(
          '[CommunityTokenTradeNotifier] Wallet address is missing for wallet ${wallet.id} on network ${wallet.network}',
        );
        throw Exception('Wallet address is missing');
      }

      Logger.info('[CommunityTokenTradeNotifier] Step 3: Getting token info');
      final tokenInfo = ref.read(tokenMarketInfoProvider(params.externalAddress)).valueOrNull;
      final communityTokenAddress = tokenInfo?.addresses.blockchain;
      if (communityTokenAddress == null || communityTokenAddress.isEmpty) {
        Logger.error(
          '[CommunityTokenTradeNotifier] Community token contract address is missing | tokenInfo=$tokenInfo',
        );
        throw StateError('Community token contract address is missing');
      }
      Logger.info(
        '[CommunityTokenTradeNotifier] Token info obtained | communityTokenAddress=$communityTokenAddress',
      );

      Logger.info('[CommunityTokenTradeNotifier] Step 4: Converting amount to blockchain units');
      final amountIn =
          toBlockchainUnits(amount, TokenizedCommunitiesConstants.creatorTokenDecimals);
      Logger.info(
        '[CommunityTokenTradeNotifier] Amount converted | amount=$amount | amountIn=$amountIn | decimals=${TokenizedCommunitiesConstants.creatorTokenDecimals}',
      );

      Logger.info('[CommunityTokenTradeNotifier] Step 5: Getting trade service');
      final service = await ref.read(tradeCommunityTokenServiceProvider.future);
      Logger.info('[CommunityTokenTradeNotifier] Trade service obtained');

      final expectedPricing = formState.quotePricing;

      if (formState.isQuoting || expectedPricing == null) {
        Logger.error(
          '[CommunityTokenTradeNotifier] Quote not ready | isQuoting=${formState.isQuoting} | expectedPricing=$expectedPricing',
        );
        throw StateError('Quote is not ready yet');
      }
      Logger.info('[CommunityTokenTradeNotifier] Quote ready | expectedPricing=$expectedPricing');

      Logger.info('[CommunityTokenTradeNotifier] Step 6: Calling sellCommunityToken service');
      Logger.info(
        '[CommunityTokenTradeNotifier] Sell parameters | '
        'externalAddress=${params.externalAddress} | '
        'amountIn=$amountIn | '
        'walletId=${wallet.id} | '
        'walletAddress=${wallet.address} | '
        'paymentTokenAddress=${token.contractAddress} | '
        'communityTokenAddress=$communityTokenAddress',
      );

      final response = await service.sellCommunityToken(
        externalAddress: params.externalAddress,
        externalAddressType: params.externalAddressType,
        amountIn: amountIn,
        walletId: wallet.id,
        walletAddress: wallet.address!,
        walletNetwork: wallet.network,
        paymentTokenAddress: resolvePaymentTokenAddress(token),
        paymentTokenTicker: token.abbreviation,
        paymentTokenDecimals: token.decimals,
        communityTokenAddress: communityTokenAddress,
        tokenDecimals: TokenizedCommunitiesConstants.creatorTokenDecimals,
        expectedPricing: expectedPricing,
        userActionSigner: signer,
        shouldSendEvents: formState.shouldSendEvents,
      );

      Logger.info(
        '[CommunityTokenTradeNotifier] sellCommunityToken response received | response=$response',
      );

      Logger.info('[CommunityTokenTradeNotifier] Step 7: Validating transaction hash');
      final txHash = _requireBroadcastedTxHash(response);
      Logger.info('[CommunityTokenTradeNotifier] Transaction hash validated | txHash=$txHash');

      Logger.info('[CommunityTokenTradeNotifier] Step 8: Saving pending transaction');
      final tokenTransactionService = ref.read(tokenTransactionServiceProvider);
      await tokenTransactionService.savePendingTransaction(
        externalAddress: params.externalAddress,
        transactionId: response['id']?.toString(),
        txHash: txHash,
        wallet: wallet,
        paymentToken: token,
        amount: amount,
        expectedPricing: expectedPricing,
        paymentCoinsGroup: formState.paymentCoinsGroup,
        communityTokenCoinsGroup: formState.communityTokenCoinsGroup,
        isSell: true,
      );
      Logger.info('[CommunityTokenTradeNotifier] Transaction saved');

      Logger.info('[CommunityTokenTradeNotifier] Step 9: Adjusting position after sell');
      ref
          .read(cachedTokenMarketInfoNotifierProvider(params.externalAddress).notifier)
          .adjustPositionAfterSell(amount);
      Logger.info('[CommunityTokenTradeNotifier] Position adjusted');

      Logger.info('[CommunityTokenTradeNotifier] Step 10: Syncing wallet data');
      unawaited(
        ref.read(walletDataSyncCoordinatorProvider).syncWalletData(),
      );

      Logger.info(
        '[CommunityTokenTradeNotifier] Sell operation completed successfully | txHash=$txHash',
      );
      return txHash;
    });
  }

  String _requireBroadcastedTxHash(Map<String, dynamic> transaction) {
    Logger.info(
      '[CommunityTokenTradeNotifier] Validating transaction | transaction=$transaction',
    );

    final status = transaction['status']?.toString() ?? '';
    if (status.isEmpty) {
      Logger.error(
        '[CommunityTokenTradeNotifier] Transaction status is missing | transaction=$transaction',
      );
      throw CommunityTokenTradeTransactionException(
        reason: 'Swap status is missing',
      );
    }

    Logger.info('[CommunityTokenTradeNotifier] Transaction status | status=$status');

    if (status.toLowerCase() != _broadcastedStatus) {
      Logger.error(
        '[CommunityTokenTradeNotifier] Transaction not broadcasted | status=$status | expected=$_broadcastedStatus',
      );
      throw CommunityTokenTradeTransactionException(
        reason: 'Swap was not broadcasted',
        status: status,
      );
    }

    final txHash = transaction['txHash']?.toString() ?? '';
    if (txHash.isEmpty) {
      Logger.error(
        '[CommunityTokenTradeNotifier] Transaction hash is missing | status=$status | transaction=$transaction',
      );
      throw CommunityTokenTradeTransactionException(
        reason: 'Swap transaction hash is missing',
        status: status,
      );
    }

    Logger.info('[CommunityTokenTradeNotifier] Transaction validated | txHash=$txHash');
    return txHash;
  }

  Future<void> _sendFirstBuyMetadataIfNeeded() async {
    Logger.info('[CommunityTokenTradeNotifier] Checking if first buy metadata needs to be sent');
    try {
      final userPrefsService = ref.read(currentUserPreferencesServiceProvider);
      if (userPrefsService == null) {
        Logger.info('[CommunityTokenTradeNotifier] User prefs service is null, skipping');
        return;
      }

      final alreadySent = userPrefsService.getValue<bool>(_firstBuyMetadataSentKey) ?? false;
      if (alreadySent) {
        Logger.info('[CommunityTokenTradeNotifier] First buy metadata already sent, skipping');
        return;
      }

      Logger.info('[CommunityTokenTradeNotifier] Getting current user metadata');
      final currentMetadata = await ref.read(currentUserMetadataProvider.future);
      if (currentMetadata == null) {
        Logger.info('[CommunityTokenTradeNotifier] Current metadata is null, skipping');
        return;
      }

      Logger.info('[CommunityTokenTradeNotifier] Getting BSC network');
      final bscNetwork = await ref.read(bscNetworkDataProvider.future);

      Logger.info('[CommunityTokenTradeNotifier] Getting main crypto wallets');
      final mainWallets = await ref.read(mainCryptoWalletsProvider.future);
      final bscWallet = mainWallets.firstWhereOrNull(
        (wallet) => wallet.network == bscNetwork.id && wallet.address != null,
      );
      if (bscWallet == null) {
        Logger.info('[CommunityTokenTradeNotifier] BSC wallet not found, skipping');
        return;
      }

      Logger.info('[CommunityTokenTradeNotifier] Updating metadata with BSC wallet');
      final currentWallets = currentMetadata.data.wallets ?? <String, String>{};
      final updatedWallets = Map<String, String>.from(currentWallets);
      if (!updatedWallets.containsKey(bscNetwork.id)) {
        updatedWallets[bscNetwork.id] = bscWallet.address!;
      }

      final updatedMetadata = currentMetadata.data.copyWith(wallets: updatedWallets);
      Logger.info('[CommunityTokenTradeNotifier] Sending updated metadata');
      await ref.read(ionConnectNotifierProvider.notifier).sendEntitiesData([updatedMetadata]);

      await userPrefsService.setValue<bool>(_firstBuyMetadataSentKey, true);
      Logger.info('[CommunityTokenTradeNotifier] First buy metadata sent successfully');
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: '[CommunityTokenTradeNotifier] Failed to send first buy metadata',
      );
    }
  }

  Future<void> _ensurePricingValidForBuy({
    required PricingResponse expectedPricing,
    required String externalAddress,
    required ExternalAddressType externalAddressType,
  }) async {
    if (!_hasRequiredBondingFields(expectedPricing)) {
      throw StateError('Quote is missing bonding curve parameters');
    }

    if (!externalAddressType.isContentToken) return;

    final creatorExternalAddress =
        MasterPubkeyResolver.creatorExternalAddressFromExternal(externalAddress);
    final creatorTokenInfo = ref.read(tokenMarketInfoProvider(creatorExternalAddress)).valueOrNull;
    final creatorTokenExists = (creatorTokenInfo?.addresses.blockchain?.trim() ?? '').isNotEmpty;

    if (!creatorTokenExists && !_hasRequiredCreatorParams(expectedPricing)) {
      throw StateError('Quote is missing creator token parameters');
    }
  }

  bool _hasRequiredBondingFields(PricingResponse pricing) {
    final address = pricing.bondingCurveAlgAddress?.trim() ?? '';
    final initial = pricing.initialPrice?.trim() ?? '';
    final finalPrice = pricing.finalPrice?.trim() ?? '';
    final supply = pricing.emissionVolume?.trim() ?? '';
    return address.isNotEmpty && initial.isNotEmpty && finalPrice.isNotEmpty && supply.isNotEmpty;
  }

  bool _hasRequiredCreatorParams(PricingResponse pricing) {
    final params = pricing.creatorTokenParams;
    if (params == null) return false;
    final address = params.bondingCurveAlgAddress?.trim() ?? '';
    final initial = params.initialPrice?.trim() ?? '';
    final finalPrice = params.finalPrice?.trim() ?? '';
    final supply = params.emissionVolume?.trim() ?? '';
    return address.isNotEmpty && initial.isNotEmpty && finalPrice.isNotEmpty && supply.isNotEmpty;
  }
}

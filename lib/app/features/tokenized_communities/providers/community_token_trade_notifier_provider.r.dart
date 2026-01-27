// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/bsc_network_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/fat_address_data_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_operation_protected_accounts_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_community_token_controller_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/tokenized_communities/utils/creator_token_utils.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_to_send_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_details.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/providers/update_wallet_view_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_data_sync_coordinator_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:ion/app/utils/retry.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_trade_notifier_provider.r.g.dart';

typedef CommunityTokenTradeNotifierParams = ({
  String externalAddress,
  ExternalAddressType externalAddressType,
  EventReference? eventReference,
});

@riverpod
class CommunityTokenTradeNotifier extends _$CommunityTokenTradeNotifier {
  static const _firstBuyMetadataSentKey = 'community_token_first_buy';
  static const _broadcastedStatus = 'broadcasted';

  static const _syncWalletDataDelay = Duration(seconds: 3);

  @override
  FutureOr<String?> build(CommunityTokenTradeNotifierParams params) => null;

  Future<void> buy(UserActionSignerNew signer) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // Check if this account is protected from token operations
      final protectedAccountsService = ref.read(tokenOperationProtectedAccountsServiceProvider);
      final isProtected = params.eventReference != null
          ? protectedAccountsService.isProtectedAccountEvent(params.eventReference!)
          : protectedAccountsService.isProtectedAccountFromExternalAddress(
              params.externalAddress,
            );
      if (isProtected) {
        throw const TokenOperationProtectedException();
      }

      final formState = ref.read(tradeCommunityTokenControllerProvider(params));

      final token = formState.selectedPaymentToken;
      final wallet = formState.targetWallet;
      final amount = formState.amount;

      if (token == null || wallet == null || amount <= 0) {
        throw StateError('Invalid form state: token, wallet, or amount is missing');
      }

      if (wallet.address == null) {
        Logger.error(
          '[CommunityTokenTradeNotifier] Wallet address is missing for wallet ${wallet.id} on network ${wallet.network}',
        );
        throw Exception('Wallet address is missing');
      }

      final amountIn = toBlockchainUnits(amount, token.decimals);
      final service = await ref.read(tradeCommunityTokenServiceProvider.future);
      final expectedPricing = formState.quotePricing;

      if (formState.isQuoting || expectedPricing == null) {
        throw StateError('Quote is not ready yet');
      }

      await _sendFirstBuyMetadataIfNeeded();

      final existingTokenInfo =
          ref.read(tokenMarketInfoProvider(params.externalAddress)).valueOrNull;
      final existingTokenAddress = existingTokenInfo?.addresses.blockchain;
      final fatAddressData = (existingTokenAddress != null && existingTokenAddress.isNotEmpty)
          ? null
          : await ref.read(
              fatAddressDataProvider(
                externalAddress: params.externalAddress,
                externalAddressType: params.externalAddressType,
                eventReference: params.eventReference,
                suggestedDetails: formState.suggestedDetails,
              ).future,
            );

      final response = await service.buyCommunityToken(
        externalAddress: params.externalAddress,
        externalAddressType: params.externalAddressType,
        amountIn: amountIn,
        walletId: wallet.id,
        walletAddress: wallet.address!,
        walletNetwork: wallet.network,
        baseTokenAddress: token.contractAddress,
        baseTokenTicker: token.abbreviation,
        tokenDecimals: token.decimals,
        expectedPricing: expectedPricing,
        fatAddressData: fatAddressData,
        userActionSigner: signer,
        shouldSendEvents: formState.shouldSendEvents,
        slippagePercent: formState.slippage,
      );

      final txHash = _requireBroadcastedTxHash(response);

      try {
        await _importTokenIfNeeded(
          existingTokenAddress,
          formState.communityTokenCoinsGroup,
        );
        // Save pending transaction to database
        // Note: If TokenInfoNotFoundException is thrown during first buy events,
        // the transaction may still be saved if it was broadcasted before the error.
        // The error is expected on first buy when token info doesn't exist yet.
        await _savePendingTransaction(
          response: response,
          txHash: txHash,
          wallet: wallet,
          paymentToken: token,
          amount: amount,
          expectedPricing: expectedPricing,
          paymentCoinsGroup: formState.paymentCoinsGroup,
        );
      } catch (error, stackTrace) {
        Logger.error(
          error,
          stackTrace: stackTrace,
          message: '[CommunityTokenTradeNotifier] Failed to import token',
        );
      }

      unawaited(
        Future.delayed(
          _syncWalletDataDelay,
          () => ref.read(walletDataSyncCoordinatorProvider).syncWalletData(),
        ),
      );

      return txHash;
    });
  }

  Future<void> sell(UserActionSignerNew signer) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // Check if this account is protected from token operations
      final protectedAccountsService = ref.read(tokenOperationProtectedAccountsServiceProvider);
      final isProtected = params.eventReference != null
          ? protectedAccountsService.isProtectedAccountEvent(params.eventReference!)
          : protectedAccountsService.isProtectedAccountFromExternalAddress(
              params.externalAddress,
            );
      if (isProtected) {
        throw const TokenOperationProtectedException();
      }

      final formState = ref.read(tradeCommunityTokenControllerProvider(params));

      final token = formState.selectedPaymentToken;
      final wallet = formState.targetWallet;
      final amount = formState.amount;

      if (token == null || wallet == null || amount <= 0) {
        throw StateError('Invalid form state: token, wallet, or amount is missing');
      }

      if (wallet.address == null) {
        Logger.error(
          '[CommunityTokenTradeNotifier] Wallet address is missing for wallet ${wallet.id} on network ${wallet.network}',
        );
        throw Exception('Wallet address is missing');
      }

      final tokenInfo = ref.read(tokenMarketInfoProvider(params.externalAddress)).valueOrNull;
      final communityTokenAddress = tokenInfo?.addresses.blockchain;
      if (communityTokenAddress == null || communityTokenAddress.isEmpty) {
        throw StateError('Community token contract address is missing');
      }

      final amountIn =
          toBlockchainUnits(amount, TokenizedCommunitiesConstants.creatorTokenDecimals);
      final service = await ref.read(tradeCommunityTokenServiceProvider.future);
      final expectedPricing = formState.quotePricing;

      if (formState.isQuoting || expectedPricing == null) {
        throw StateError('Quote is not ready yet');
      }

      final response = await service.sellCommunityToken(
        externalAddress: params.externalAddress,
        amountIn: amountIn,
        walletId: wallet.id,
        walletAddress: wallet.address!,
        walletNetwork: wallet.network,
        paymentTokenAddress: token.contractAddress,
        paymentTokenTicker: token.abbreviation,
        paymentTokenDecimals: token.decimals,
        communityTokenAddress: communityTokenAddress,
        tokenDecimals: TokenizedCommunitiesConstants.creatorTokenDecimals,
        expectedPricing: expectedPricing,
        userActionSigner: signer,
        shouldSendEvents: formState.shouldSendEvents,
      );

      final txHash = _requireBroadcastedTxHash(response);

      unawaited(
        ref.read(walletDataSyncCoordinatorProvider).syncWalletData(),
      );
      return txHash;
    });
  }

  String _requireBroadcastedTxHash(Map<String, dynamic> transaction) {
    final status = transaction['status']?.toString() ?? '';
    if (status.isEmpty) {
      throw CommunityTokenTradeTransactionException(
        reason: 'Swap status is missing',
      );
    }

    if (status.toLowerCase() != _broadcastedStatus) {
      throw CommunityTokenTradeTransactionException(
        reason: 'Swap was not broadcasted',
        status: status,
      );
    }

    final txHash = transaction['txHash']?.toString() ?? '';
    if (txHash.isEmpty) {
      throw CommunityTokenTradeTransactionException(
        reason: 'Swap transaction hash is missing',
        status: status,
      );
    }

    return txHash;
  }

  Future<void> _sendFirstBuyMetadataIfNeeded() async {
    try {
      final userPrefsService = ref.read(currentUserPreferencesServiceProvider);
      if (userPrefsService == null) return;

      final alreadySent = userPrefsService.getValue<bool>(_firstBuyMetadataSentKey) ?? false;
      if (alreadySent) return;

      final currentMetadata = await ref.read(currentUserMetadataProvider.future);
      if (currentMetadata == null) return;

      final bscNetwork = await ref.read(bscNetworkDataProvider.future);

      final mainWallets = await ref.read(mainCryptoWalletsProvider.future);
      final bscWallet = mainWallets.firstWhereOrNull(
        (wallet) => wallet.network == bscNetwork.id && wallet.address != null,
      );
      if (bscWallet == null) return;

      final currentWallets = currentMetadata.data.wallets ?? <String, String>{};
      final updatedWallets = Map<String, String>.from(currentWallets);
      if (!updatedWallets.containsKey(bscNetwork.id)) {
        updatedWallets[bscNetwork.id] = bscWallet.address!;
      }

      final updatedMetadata = currentMetadata.data.copyWith(wallets: updatedWallets);
      await ref.read(ionConnectNotifierProvider.notifier).sendEntitiesData([updatedMetadata]);

      await userPrefsService.setValue<bool>(_firstBuyMetadataSentKey, true);
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: '[CommunityTokenTradeNotifier] Failed to send first buy metadata',
      );
    }
  }

  Future<void> _savePendingTransaction({
    required Map<String, dynamic> response,
    required String txHash,
    required Wallet wallet,
    required CoinData paymentToken,
    required double amount,
    required PricingResponse expectedPricing,
    required CoinsGroup? paymentCoinsGroup,
  }) async {
    try {
      final walletView = await ref.read(currentWalletViewDataProvider.future);
      final network = await ref.read(networkByIdProvider(wallet.network).future);

      if (network == null) {
        Logger.error(
          Exception('Network not found for wallet network: ${wallet.network}'),
          message:
              '[CommunityTokenTradeNotifier] Network not found for wallet network: ${wallet.network}',
        );
        return;
      }

      // Get creator token info (may be null on first buy)
      final tokenInfo = ref.read(tokenMarketInfoProvider(params.externalAddress)).valueOrNull;

      late CoinData creatorTokenCoin;
      late CoinsGroup creatorTokenCoinsGroup;

      // Try to get coin from database by contract address or symbolGroup
      // For first buy, tokenInfo may be null, so we need to handle that case
      final existingTokenAddress = tokenInfo?.addresses.blockchain;
      final tokenSymbolGroup = tokenInfo?.title;
      Logger.info(
        '[CommunityTokenTradeNotifier] existingTokenAddress: $existingTokenAddress\n'
        '  tokenSymbolGroup: $tokenSymbolGroup',
      );

      if (existingTokenAddress != null && existingTokenAddress.isNotEmpty) {
        Logger.info(
          '[CommunityTokenTradeNotifier] Searching database for coin with contractAddress: $existingTokenAddress, network: ${network.id}',
        );
        final coinsRepository = ref.read(coinsRepositoryProvider);

        // First try by contract address
        var coins = await coinsRepository.getCoinsByFilters(
          contractAddresses: [existingTokenAddress],
          networks: [network.id],
        );

        Logger.info(
          '[CommunityTokenTradeNotifier] Found ${coins.length} coins in database by contractAddress',
        );

        // If not found, try by symbolGroup
        if (coins.isEmpty && tokenSymbolGroup != null && tokenSymbolGroup.isNotEmpty) {
          Logger.info(
            '[CommunityTokenTradeNotifier] Searching database for coin with symbolGroup: $tokenSymbolGroup, network: ${network.id}',
          );
          coins = await coinsRepository.getCoinsByFilters(
            symbolGroups: [tokenSymbolGroup],
            networks: [network.id],
          );
          Logger.info(
            '[CommunityTokenTradeNotifier] Found ${coins.length} coins in database by symbolGroup',
          );
        }

        if (coins.isNotEmpty) {
          for (final coin in coins) {
            Logger.info(
              '[CommunityTokenTradeNotifier]   - coinId: ${coin.id}, contractAddress: ${coin.contractAddress}, symbolGroup: ${coin.symbolGroup}',
            );
          }
        }

        if (coins.isNotEmpty) {
          // Found coin in database - use it
          final dbCoin = coins.first;
          final coinInWallet = CoinInWalletData(
            coin: dbCoin,
            amount: tokenInfo?.marketData.position?.amountValue ?? 0.0,
            rawAmount: (tokenInfo?.marketData.position?.amountValue ?? 0.0).toString(),
            balanceUSD: (tokenInfo?.marketData.position?.amountValue ?? 0.0) *
                (tokenInfo?.marketData.priceUSD ?? 0.0),
            walletId: wallet.id,
          );

          creatorTokenCoin = dbCoin;
          creatorTokenCoinsGroup = CoinsGroup(
            name: tokenInfo?.title ?? params.externalAddress,
            iconUrl: tokenInfo?.imageUrl ?? '',
            symbolGroup: tokenInfo?.title ?? params.externalAddress,
            abbreviation: tokenInfo?.title ?? params.externalAddress,
            coins: [coinInWallet],
            totalAmount: tokenInfo?.marketData.position?.amountValue ?? 0.0,
            totalBalanceUSD: (tokenInfo?.marketData.position?.amountValue ?? 0.0) *
                (tokenInfo?.marketData.priceUSD ?? 0.0),
          );
          Logger.info(
            '[CommunityTokenTradeNotifier] ✓ Using creator token coin from database: ${creatorTokenCoin.id}',
          );
        } else {
          // Coin not in database yet - try to get from backend
          Logger.info(
            '[CommunityTokenTradeNotifier] Coin not in database, fetching from backend...',
          );
          try {
            final ionIdentity = await ref.read(ionIdentityClientProvider.future);
            final coin = await ionIdentity.coins.getCoinData(
              contractAddress: existingTokenAddress,
              network: network.id,
            );
            final coinData = CoinData.fromDTO(coin, network);

            Logger.info(
              '[CommunityTokenTradeNotifier] Backend returned coin with id: ${coinData.id}',
            );

            // Use the coinId from backend (UUID format)
            final coinInWallet = CoinInWalletData(
              coin: coinData,
              amount: tokenInfo?.marketData.position?.amountValue ?? 0.0,
              rawAmount: (tokenInfo?.marketData.position?.amountValue ?? 0.0).toString(),
              balanceUSD: (tokenInfo?.marketData.position?.amountValue ?? 0.0) *
                  (tokenInfo?.marketData.priceUSD ?? 0.0),
              walletId: wallet.id,
            );

            creatorTokenCoin = coinData;
            creatorTokenCoinsGroup = CoinsGroup(
              name: tokenInfo?.title ?? params.externalAddress,
              iconUrl: tokenInfo?.imageUrl ?? '',
              symbolGroup: tokenInfo?.title ?? params.externalAddress,
              abbreviation: tokenInfo?.title ?? params.externalAddress,
              coins: [coinInWallet],
              totalAmount: tokenInfo?.marketData.position?.amountValue ?? 0.0,
              totalBalanceUSD: (tokenInfo?.marketData.position?.amountValue ?? 0.0) *
                  (tokenInfo?.marketData.priceUSD ?? 0.0),
            );
            Logger.info(
              '[CommunityTokenTradeNotifier] ✓ Using creator token coin from backend: ${creatorTokenCoin.id}',
            );
          } catch (e) {
            // Backend returned 404 (token doesn't exist yet) or other error
            // Fall back to creating minimal coin data or deriving from tokenInfo
            Logger.info(
              '[CommunityTokenTradeNotifier] ✗ Failed to get coin from backend: $e\n'
              '  This is expected on first buy when token contract does not exist yet',
            );

            // Calculate amounts for fallback
            const creatorTokenDecimals = TokenizedCommunitiesConstants.creatorTokenDecimals;
            final creatorTokenAmount = fromBlockchainUnits(
              expectedPricing.amount,
              creatorTokenDecimals,
            );
            final creatorTokenRawAmount = expectedPricing.amount;
            final amountUSD = expectedPricing.amountUSD;

            // Try to derive from tokenInfo if available
            CoinsGroup? derivedGroup;
            if (tokenInfo != null) {
              derivedGroup = await CreatorTokenUtils.deriveCreatorTokenCoinsGroup(
                token: tokenInfo,
                externalAddress: params.externalAddress,
                network: network,
              );
            }

            // If derive failed or tokenInfo is null, create minimal coin data
            if (derivedGroup == null || derivedGroup.coins.isEmpty) {
              Logger.info(
                '[CommunityTokenTradeNotifier] Creating minimal coin data from external address',
              );
              final minimalCoin = CoinData(
                id: params.externalAddress,
                contractAddress:
                    existingTokenAddress, // existingTokenAddress is non-null here (checked in if condition)
                decimals: creatorTokenDecimals,
                iconUrl: tokenInfo?.imageUrl ?? '',
                name: tokenInfo?.title ?? params.externalAddress,
                network: network,
                priceUSD: tokenInfo?.marketData.priceUSD ?? 0.0,
                abbreviation: tokenInfo?.title ?? params.externalAddress,
                symbolGroup: tokenInfo?.title ?? params.externalAddress,
                syncFrequency: const Duration(hours: 1),
              );

              final coinInWallet = CoinInWalletData(
                coin: minimalCoin,
                amount: creatorTokenAmount,
                rawAmount: creatorTokenRawAmount,
                balanceUSD: amountUSD,
                walletId: wallet.id,
              );

              creatorTokenCoin = minimalCoin;
              creatorTokenCoinsGroup = CoinsGroup(
                name: tokenInfo?.title ?? params.externalAddress,
                iconUrl: tokenInfo?.imageUrl ?? '',
                symbolGroup: tokenInfo?.title ?? params.externalAddress,
                abbreviation: tokenInfo?.title ?? params.externalAddress,
                coins: [coinInWallet],
                totalAmount: creatorTokenAmount,
                totalBalanceUSD: amountUSD,
              );
              Logger.info(
                '[CommunityTokenTradeNotifier] ✗ Using minimal creator token coin (fallback): ${creatorTokenCoin.id}',
              );
            } else {
              creatorTokenCoin = derivedGroup.coins.first.coin;
              creatorTokenCoinsGroup = derivedGroup;
              Logger.info(
                '[CommunityTokenTradeNotifier] ✗ Using derived creator token coin (fallback): ${creatorTokenCoin.id}',
              );
            }
          }
        }
      } else {
        // First buy - token doesn't exist yet, use externalAddress as coinId
        Logger.info('[CommunityTokenTradeNotifier] First buy - token address not available yet');

        // Calculate amounts first (needed for creating minimal coin data)
        const creatorTokenDecimals = TokenizedCommunitiesConstants.creatorTokenDecimals;
        final creatorTokenAmount = fromBlockchainUnits(
          expectedPricing.amount,
          creatorTokenDecimals,
        );
        final creatorTokenRawAmount = expectedPricing.amount;
        final amountUSD = expectedPricing.amountUSD;

        // Try to derive from tokenInfo if available
        CoinsGroup? derivedGroup;
        if (tokenInfo != null) {
          derivedGroup = await CreatorTokenUtils.deriveCreatorTokenCoinsGroup(
            token: tokenInfo,
            externalAddress: params.externalAddress,
            network: network,
          );
        }

        // If derive failed or tokenInfo is null, create minimal coin data from external address
        if (derivedGroup == null || derivedGroup.coins.isEmpty) {
          Logger.info(
            '[CommunityTokenTradeNotifier] Creating minimal coin data from external address for first buy',
          );
          final minimalCoin = CoinData(
            id: params.externalAddress,
            contractAddress: '', // Will be set when token is created
            decimals: creatorTokenDecimals,
            iconUrl: '',
            name: params.externalAddress,
            network: network,
            priceUSD: 0,
            abbreviation: params.externalAddress,
            symbolGroup: params.externalAddress,
            syncFrequency: const Duration(hours: 1),
          );

          final coinInWallet = CoinInWalletData(
            coin: minimalCoin,
            amount: creatorTokenAmount,
            rawAmount: creatorTokenRawAmount,
            balanceUSD: amountUSD,
            walletId: wallet.id,
          );

          creatorTokenCoin = minimalCoin;
          creatorTokenCoinsGroup = CoinsGroup(
            name: params.externalAddress,
            iconUrl: '',
            symbolGroup: params.externalAddress,
            abbreviation: params.externalAddress,
            coins: [coinInWallet],
            totalAmount: creatorTokenAmount,
            totalBalanceUSD: amountUSD,
          );
          Logger.info(
            '[CommunityTokenTradeNotifier] ✗ Using minimal creator token coin (first buy): ${creatorTokenCoin.id}',
          );
        } else {
          creatorTokenCoin = derivedGroup.coins.first.coin;
          creatorTokenCoinsGroup = derivedGroup;
          Logger.info(
            '[CommunityTokenTradeNotifier] ✗ Using derived creator token coin (first buy): ${creatorTokenCoin.id}',
          );
        }
      }

      // Calculate amounts
      final paymentRawAmount = toBlockchainUnits(amount, paymentToken.decimals).toString();
      const creatorTokenDecimals = TokenizedCommunitiesConstants.creatorTokenDecimals;
      final creatorTokenAmount = fromBlockchainUnits(
        expectedPricing.amount,
        creatorTokenDecimals,
      );
      final creatorTokenRawAmount = expectedPricing.amount;
      final amountUSD = expectedPricing.amountUSD;

      const status = TransactionStatus.broadcasted;
      final dateRequested = DateTime.now();
      final transactionsRepository = await ref.read(transactionsRepositoryProvider.future);

      // Save transaction for payment token (send)
      final paymentTokenCoinsGroup = paymentCoinsGroup ??
          CoinsGroup(
            name: paymentToken.name,
            iconUrl: paymentToken.iconUrl,
            symbolGroup: paymentToken.symbolGroup,
            abbreviation: paymentToken.abbreviation,
            coins: [],
          );

      final paymentSelectedOption = paymentTokenCoinsGroup.coins.firstWhereOrNull(
            (coin) => coin.coin.id == paymentToken.id,
          ) ??
          CoinInWalletData(
            coin: paymentToken,
            amount: amount,
            rawAmount: paymentRawAmount,
            balanceUSD: amountUSD,
            walletId: wallet.id,
          );

      final paymentAssetData = CryptoAssetToSendData.coin(
        coinsGroup: paymentTokenCoinsGroup,
        amount: amount,
        rawAmount: paymentRawAmount,
        amountUSD: amountUSD,
        selectedOption: paymentSelectedOption,
      );

      final paymentTransaction = TransactionDetails(
        id: response['id']?.toString(),
        txHash: txHash,
        network: network,
        type: TransactionType.send,
        assetData: paymentAssetData,
        status: status,
        walletViewId: walletView.id,
        senderAddress: wallet.address,
        receiverAddress: null,
        walletViewName: walletView.name,
        participantPubkey: null,
        dateRequested: dateRequested,
        dateConfirmed: null,
        dateBroadcasted: dateRequested,
        nativeCoin: null,
        networkFeeOption: null,
        memo: null,
      );

      // Save transaction for creator token (receive)
      final creatorSelectedOption = creatorTokenCoinsGroup.coins.firstWhereOrNull(
            (coin) => coin.coin.id == creatorTokenCoin.id,
          ) ??
          CoinInWalletData(
            coin: creatorTokenCoin,
            amount: creatorTokenAmount,
            rawAmount: creatorTokenRawAmount,
            balanceUSD: amountUSD,
            walletId: wallet.id,
          );

      final creatorAssetData = CryptoAssetToSendData.coin(
        coinsGroup: creatorTokenCoinsGroup,
        amount: creatorTokenAmount,
        rawAmount: creatorTokenRawAmount,
        amountUSD: amountUSD,
        selectedOption: creatorSelectedOption,
      );

      final creatorTransaction = TransactionDetails(
        id: response['id']?.toString(),
        txHash: txHash,
        network: network,
        type: TransactionType.receive,
        assetData: creatorAssetData,
        status: status,
        walletViewId: walletView.id,
        senderAddress: wallet.address,
        receiverAddress: wallet.address,
        walletViewName: walletView.name,
        participantPubkey: null,
        dateRequested: dateRequested,
        dateConfirmed: null,
        dateBroadcasted: dateRequested,
        nativeCoin: null,
        networkFeeOption: null,
        memo: null,
      );

      // Save both transactions
      Logger.info(
        '[CommunityTokenTradeNotifier] === SAVING PENDING CREATOR TOKEN TRANSACTIONS ===\n'
        'Payment Transaction:\n'
        '  txHash: ${paymentTransaction.txHash}\n'
        '  type: ${paymentTransaction.type.value}\n'
        '  coinId: ${paymentTransaction.assetData.mapOrNull(coin: (c) => c.selectedOption?.coin.id)}\n'
        '  coinName: ${paymentTransaction.assetData.mapOrNull(coin: (c) => c.coinsGroup.name)}\n'
        '  amount: ${paymentTransaction.assetData.mapOrNull(coin: (c) => c.amount)}\n'
        '  status: ${paymentTransaction.status.toJson()}\n'
        '  walletViewId: ${paymentTransaction.walletViewId}\n'
        'Creator Transaction:\n'
        '  txHash: ${creatorTransaction.txHash}\n'
        '  type: ${creatorTransaction.type.value}\n'
        '  coinId: ${creatorTransaction.assetData.mapOrNull(coin: (c) => c.selectedOption?.coin.id)}\n'
        '  coinName: ${creatorTransaction.assetData.mapOrNull(coin: (c) => c.coinsGroup.name)}\n'
        '  amount: ${creatorTransaction.assetData.mapOrNull(coin: (c) => c.amount)}\n'
        '  status: ${creatorTransaction.status.toJson()}\n'
        '  walletViewId: ${creatorTransaction.walletViewId}\n'
        'Creator Token Coin Details:\n'
        '  coinId: ${creatorTokenCoin.id}\n'
        '  contractAddress: ${creatorTokenCoin.contractAddress}\n'
        '  symbolGroup: ${creatorTokenCoin.symbolGroup}\n'
        '  abbreviation: ${creatorTokenCoin.abbreviation}\n'
        '==================================================',
      );

      await Future.wait([
        transactionsRepository.saveTransactionDetails(paymentTransaction),
        transactionsRepository.saveTransactionDetails(creatorTransaction),
      ]);

      Logger.info('[CommunityTokenTradeNotifier] Successfully saved both pending transactions');
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message:
            '[CommunityTokenTradeNotifier] Failed to save pending transaction for creator token buy',
      );
    }
  }

  Future<void> _importTokenIfNeeded(
    String? existingTokenAddress,
    CoinsGroup? communityTokenCoinsGroup,
  ) async {
    final tokenData = communityTokenCoinsGroup?.coins.firstOrNull?.coin;

    String? contractAddress;
    NetworkData? network;

    if (tokenData != null) {
      contractAddress = tokenData.contractAddress;
      network = tokenData.network;
    } else if (existingTokenAddress == null || existingTokenAddress.isEmpty) {
      // First buy - token was just created, need to fetch the address
      // Get network from BSC wallet first
      final wallets = ref.read(walletsNotifierProvider).valueOrNull ?? [];
      final bscWallet = CreatorTokenUtils.findBscWallet(wallets);
      if (bscWallet == null) {
        return;
      }
      network = await ref.read(networkByIdProvider(bscWallet.network).future);
      if (network == null) {
        return;
      }

      // Try to get token address from tokenMarketInfoProvider (might be updated via stream)
      final tokenInfo = ref.read(tokenMarketInfoProvider(params.externalAddress)).valueOrNull;
      contractAddress = tokenInfo?.addresses.blockchain;

      // If still null or empty, retry fetching with fresh data (token might be propagating)
      if (contractAddress == null || contractAddress.isEmpty) {
        try {
          final service = await ref.read(tradeCommunityTokenServiceProvider.future);
          contractAddress = await withRetry<String>(
            ({Object? error}) async {
              final freshTokenInfo = await service.fetchTokenInfoFresh(params.externalAddress);
              final tokenAddress = freshTokenInfo?.addresses.blockchain;
              if (tokenAddress == null || tokenAddress.isEmpty) {
                throw TokenAddressNotFoundException(params.externalAddress);
              }
              return tokenAddress;
            },
            maxRetries: 5,
            initialDelay: const Duration(milliseconds: 500),
            maxDelay: const Duration(seconds: 2),
            retryWhen: (error) => error is TokenAddressNotFoundException,
          );
          // After successful retry, contractAddress is guaranteed to be non-null and non-empty
        } catch (error, stackTrace) {
          Logger.error(
            error,
            stackTrace: stackTrace,
            message: '[CommunityTokenTradeNotifier] Failed to fetch token address after first buy',
          );
          return;
        }
      }

      // Verify contractAddress is not empty (it's already non-null if we reach here)
      if (contractAddress.isEmpty) {
        return;
      }
    } else {
      // Not a first buy, but tokenData is null - this shouldn't happen
      return;
    }

    // At this point, contractAddress and network are guaranteed to be non-null
    // (either from tokenData or successfully fetched in first-buy path)

    // Only skip import if existingTokenAddress exists and doesn't match.
    // For first buy (existingTokenAddress is null/empty), we should proceed with import.
    final shouldSkip = existingTokenAddress != null &&
        existingTokenAddress.isNotEmpty &&
        existingTokenAddress.toLowerCase() != contractAddress.toLowerCase();

    if (shouldSkip) {
      return;
    }

    final ionIdentity = await ref.read(ionIdentityClientProvider.future);

    final coin = await ionIdentity.coins.getCoinData(
      contractAddress: contractAddress,
      network: network.id,
    );

    final coinData = CoinData.fromDTO(coin, network);

    final coinsRepository = ref.read(coinsRepositoryProvider);
    final existingCoin = await coinsRepository.getCoinById(coin.id);
    if (existingCoin != null) return;

    await coinsRepository.updateCoins(
      [
        coinData.toDB(),
      ],
    );

    final currentWalletView = await ref.read(currentWalletViewDataProvider.future);
    final walletCoins =
        currentWalletView.coinGroups.expand((e) => e.coins).map((e) => e.coin).toList();

    final updatedCoins = [...walletCoins, coinData];

    await ref.read(updateWalletViewNotifierProvider.notifier).updateWalletView(
          walletView: currentWalletView,
          updatedCoinsList: updatedCoins,
        );
  }
}

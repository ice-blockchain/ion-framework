// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/tokenized_communities/utils/creator_token_utils.dart';
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
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_transaction_service.r.g.dart';

@riverpod
TokenTransactionService tokenTransactionService(Ref ref) {
  return TokenTransactionService(
    ref: ref,
  );
}

class TokenTransactionService {
  TokenTransactionService({
    required Ref ref,
  }) : _ref = ref;

  final Ref _ref;

  Future<void> savePendingTransaction({
    required String externalAddress,
    required String? transactionId,
    required String txHash,
    required Wallet wallet,
    required CoinData paymentToken,
    required double amount,
    required PricingResponse expectedPricing,
    required CoinsGroup? paymentCoinsGroup,
  }) async {
    try {
      final walletView = await _ref.read(currentWalletViewDataProvider.future);
      final network = await _getNetwork(wallet.network);
      if (network == null) return;

      final tokenInfo = await _ref.read(tokenMarketInfoProvider(externalAddress).future);
      final tokenData = await _resolveTokenCoin(
        externalAddress: externalAddress,
        tokenInfo: tokenInfo,
        network: network,
        wallet: wallet,
        expectedPricing: expectedPricing,
      );

      final amounts = _calculateAmounts(
        amount: amount,
        paymentToken: paymentToken,
        expectedPricing: expectedPricing,
      );

      final transactions = _createTransactions(
        transactionId: transactionId,
        txHash: txHash,
        wallet: wallet,
        walletView: walletView,
        network: network,
        paymentToken: paymentToken,
        paymentCoinsGroup: paymentCoinsGroup,
        paymentAmount: amount,
        tokenCoin: tokenData.coin,
        tokenCoinsGroup: tokenData.coinsGroup,
        amounts: amounts,
      );

      await _saveTransactions(transactions);
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: '[TokenTransactionService] Failed to save pending transaction for token buy',
      );
    }
  }

  Future<NetworkData?> _getNetwork(String networkId) async {
    final network = await _ref.read(networkByIdProvider(networkId).future);
    if (network == null) {
      Logger.error(
        Exception('Network not found for wallet network: $networkId'),
        message: '[TokenTransactionService] Network not found for wallet network: $networkId',
      );
    }
    return network;
  }

  Future<({CoinData coin, CoinsGroup coinsGroup})> _resolveTokenCoin({
    required String externalAddress,
    required CommunityToken? tokenInfo,
    required NetworkData network,
    required Wallet wallet,
    required PricingResponse expectedPricing,
  }) async {
    final existingTokenAddress = tokenInfo?.addresses.blockchain;
    final tokenSymbolGroup = tokenInfo?.title;
    Logger.info(
      '[TokenTransactionService] existingTokenAddress: $existingTokenAddress\n'
      '  tokenSymbolGroup: $tokenSymbolGroup',
    );

    if (existingTokenAddress != null && existingTokenAddress.isNotEmpty) {
      return _resolveTokenCoinWithAddress(
        externalAddress: externalAddress,
        tokenInfo: tokenInfo,
        existingTokenAddress: existingTokenAddress,
        tokenSymbolGroup: tokenSymbolGroup,
        network: network,
        wallet: wallet,
        expectedPricing: expectedPricing,
      );
    } else {
      return _resolveTokenCoinFirstBuy(
        externalAddress: externalAddress,
        tokenInfo: tokenInfo,
        network: network,
        wallet: wallet,
        expectedPricing: expectedPricing,
      );
    }
  }

  Future<({CoinData coin, CoinsGroup coinsGroup})> _resolveTokenCoinWithAddress({
    required String externalAddress,
    required CommunityToken? tokenInfo,
    required String existingTokenAddress,
    required String? tokenSymbolGroup,
    required NetworkData network,
    required Wallet wallet,
    required PricingResponse expectedPricing,
  }) async {
    Logger.info(
      '[TokenTransactionService] Searching database for coin with contractAddress: $existingTokenAddress, network: ${network.id}',
    );
    final coins = await _searchCoinsInDatabase(
      existingTokenAddress: existingTokenAddress,
      tokenSymbolGroup: tokenSymbolGroup,
      network: network,
    );

    if (coins.isNotEmpty) {
      return _createCoinDataFromDatabase(
        coin: coins.first,
        tokenInfo: tokenInfo,
        externalAddress: externalAddress,
        wallet: wallet,
      );
    }

    // Coin not in database yet - try to get from backend
    try {
      return _fetchCoinFromBackend(
        existingTokenAddress: existingTokenAddress,
        tokenInfo: tokenInfo,
        externalAddress: externalAddress,
        network: network,
        wallet: wallet,
      );
    } catch (e) {
      // Backend returned 404 (token doesn't exist yet) or other error
      // Fall back to creating minimal coin data or deriving from tokenInfo
      return _createFallbackCoinData(
        externalAddress: externalAddress,
        existingTokenAddress: existingTokenAddress,
        tokenInfo: tokenInfo,
        network: network,
        wallet: wallet,
        expectedPricing: expectedPricing,
      );
    }
  }

  Future<({CoinData coin, CoinsGroup coinsGroup})> _resolveTokenCoinFirstBuy({
    required String externalAddress,
    required CommunityToken? tokenInfo,
    required NetworkData network,
    required Wallet wallet,
    required PricingResponse expectedPricing,
  }) async {
    Logger.info('[TokenTransactionService] First buy - token address not available yet');
    return _createFallbackCoinData(
      externalAddress: externalAddress,
      existingTokenAddress: null,
      tokenInfo: tokenInfo,
      network: network,
      wallet: wallet,
      expectedPricing: expectedPricing,
      isFirstBuy: true,
    );
  }

  Future<List<CoinData>> _searchCoinsInDatabase({
    required String existingTokenAddress,
    required String? tokenSymbolGroup,
    required NetworkData network,
  }) async {
    final coinsRepository = _ref.read(coinsRepositoryProvider);

    // First try by contract address
    var coins = await coinsRepository.getCoinsByFilters(
      contractAddresses: [existingTokenAddress],
      networks: [network.id],
    );

    Logger.info(
      '[TokenTransactionService] Found ${coins.length} coins in database by contractAddress',
    );

    // If not found, try by symbolGroup
    if (coins.isEmpty && tokenSymbolGroup != null && tokenSymbolGroup.isNotEmpty) {
      Logger.info(
        '[TokenTransactionService] Searching database for coin with symbolGroup: $tokenSymbolGroup, network: ${network.id}',
      );
      coins = await coinsRepository.getCoinsByFilters(
        symbolGroups: [tokenSymbolGroup],
        networks: [network.id],
      );
      Logger.info(
        '[TokenTransactionService] Found ${coins.length} coins in database by symbolGroup',
      );
    }

    if (coins.isNotEmpty) {
      for (final coin in coins) {
        Logger.info(
          '[TokenTransactionService]   - coinId: ${coin.id}, contractAddress: ${coin.contractAddress}, symbolGroup: ${coin.symbolGroup}',
        );
      }
    }

    return coins;
  }

  ({CoinData coin, CoinsGroup coinsGroup}) _createCoinDataFromDatabase({
    required CoinData coin,
    required CommunityToken? tokenInfo,
    required String externalAddress,
    required Wallet wallet,
  }) {
    final coinInWallet = CoinInWalletData(
      coin: coin,
      amount: tokenInfo?.marketData.position?.amountValue ?? 0.0,
      rawAmount: (tokenInfo?.marketData.position?.amountValue ?? 0.0).toString(),
      balanceUSD: (tokenInfo?.marketData.position?.amountValue ?? 0.0) *
          (tokenInfo?.marketData.priceUSD ?? 0.0),
      walletId: wallet.id,
    );

    final coinsGroup = CoinsGroup(
      name: tokenInfo?.title ?? externalAddress,
      iconUrl: tokenInfo?.imageUrl ?? '',
      symbolGroup: tokenInfo?.title ?? externalAddress,
      abbreviation: tokenInfo?.title ?? externalAddress,
      coins: [coinInWallet],
      totalAmount: tokenInfo?.marketData.position?.amountValue ?? 0.0,
      totalBalanceUSD: (tokenInfo?.marketData.position?.amountValue ?? 0.0) *
          (tokenInfo?.marketData.priceUSD ?? 0.0),
    );

    Logger.info(
      '[TokenTransactionService] ✓ Using token coin from database: ${coin.id}',
    );

    return (coin: coin, coinsGroup: coinsGroup);
  }

  Future<({CoinData coin, CoinsGroup coinsGroup})> _fetchCoinFromBackend({
    required String existingTokenAddress,
    required CommunityToken? tokenInfo,
    required String externalAddress,
    required NetworkData network,
    required Wallet wallet,
  }) async {
    Logger.info(
      '[TokenTransactionService] Coin not in database, fetching from backend...',
    );
    final ionIdentity = await _ref.read(ionIdentityClientProvider.future);
    final coin = await ionIdentity.coins.getCoinData(
      contractAddress: existingTokenAddress,
      network: network.id,
    );
    final coinData = CoinData.fromDTO(coin, network);

    Logger.info(
      '[TokenTransactionService] Backend returned coin with id: ${coinData.id}',
    );

    final coinInWallet = CoinInWalletData(
      coin: coinData,
      amount: tokenInfo?.marketData.position?.amountValue ?? 0.0,
      rawAmount: (tokenInfo?.marketData.position?.amountValue ?? 0.0).toString(),
      balanceUSD: (tokenInfo?.marketData.position?.amountValue ?? 0.0) *
          (tokenInfo?.marketData.priceUSD ?? 0.0),
      walletId: wallet.id,
    );

    final coinsGroup = CoinsGroup(
      name: tokenInfo?.title ?? externalAddress,
      iconUrl: tokenInfo?.imageUrl ?? '',
      symbolGroup: tokenInfo?.title ?? externalAddress,
      abbreviation: tokenInfo?.title ?? externalAddress,
      coins: [coinInWallet],
      totalAmount: tokenInfo?.marketData.position?.amountValue ?? 0.0,
      totalBalanceUSD: (tokenInfo?.marketData.position?.amountValue ?? 0.0) *
          (tokenInfo?.marketData.priceUSD ?? 0.0),
    );

    Logger.info(
      '[TokenTransactionService] ✓ Using token coin from backend: ${coinData.id}',
    );

    return (coin: coinData, coinsGroup: coinsGroup);
  }

  Future<({CoinData coin, CoinsGroup coinsGroup})> _createFallbackCoinData({
    required String externalAddress,
    required String? existingTokenAddress,
    required CommunityToken? tokenInfo,
    required NetworkData network,
    required Wallet wallet,
    required PricingResponse expectedPricing,
    bool isFirstBuy = false,
  }) async {
    Logger.info(
      isFirstBuy
          ? '[TokenTransactionService] ✗ Failed to get coin from backend\n'
              '  This is expected on first buy when token contract does not exist yet'
          : '[TokenTransactionService] Creating minimal coin data from external address for first buy',
    );

    const tokenDecimals = TokenizedCommunitiesConstants.creatorTokenDecimals;
    final tokenAmount = fromBlockchainUnits(
      expectedPricing.amount,
      tokenDecimals,
    );
    final tokenRawAmount = expectedPricing.amount;
    final amountUSD = expectedPricing.amountUSD;

    // Try to derive from tokenInfo if available
    CoinsGroup? derivedGroup;
    if (tokenInfo != null) {
      derivedGroup = await CreatorTokenUtils.deriveCreatorTokenCoinsGroup(
        token: tokenInfo,
        externalAddress: externalAddress,
        network: network,
      );
    }

    // If derive failed or tokenInfo is null, create minimal coin data
    if (derivedGroup == null || derivedGroup.coins.isEmpty) {
      return _createMinimalCoinData(
        externalAddress: externalAddress,
        existingTokenAddress: existingTokenAddress,
        tokenInfo: tokenInfo,
        network: network,
        wallet: wallet,
        tokenAmount: tokenAmount,
        tokenRawAmount: tokenRawAmount,
        amountUSD: amountUSD,
        isFirstBuy: isFirstBuy,
      );
    } else {
      Logger.info(
        '[TokenTransactionService] ✗ Using derived token coin (${isFirstBuy ? 'first buy' : 'fallback'}): ${derivedGroup.coins.first.coin.id}',
      );
      return (
        coin: derivedGroup.coins.first.coin,
        coinsGroup: derivedGroup,
      );
    }
  }

  ({CoinData coin, CoinsGroup coinsGroup}) _createMinimalCoinData({
    required String externalAddress,
    required String? existingTokenAddress,
    required CommunityToken? tokenInfo,
    required NetworkData network,
    required Wallet wallet,
    required double tokenAmount,
    required String tokenRawAmount,
    required double amountUSD,
    required bool isFirstBuy,
  }) {
    Logger.info(
      '[TokenTransactionService] Creating minimal coin data from external address${isFirstBuy ? ' for first buy' : ''}',
    );

    const tokenDecimals = TokenizedCommunitiesConstants.creatorTokenDecimals;
    final minimalCoin = CoinData(
      id: externalAddress,
      contractAddress: existingTokenAddress ?? '',
      decimals: tokenDecimals,
      iconUrl: tokenInfo?.imageUrl ?? '',
      name: tokenInfo?.title ?? externalAddress,
      network: network,
      priceUSD: tokenInfo?.marketData.priceUSD ?? 0.0,
      abbreviation: tokenInfo?.title ?? externalAddress,
      symbolGroup: tokenInfo?.title ?? externalAddress,
      syncFrequency: const Duration(hours: 1),
    );

    final coinInWallet = CoinInWalletData(
      coin: minimalCoin,
      amount: tokenAmount,
      rawAmount: tokenRawAmount,
      balanceUSD: amountUSD,
      walletId: wallet.id,
    );

    final coinsGroup = CoinsGroup(
      name: tokenInfo?.title ?? externalAddress,
      iconUrl: tokenInfo?.imageUrl ?? '',
      symbolGroup: tokenInfo?.title ?? externalAddress,
      abbreviation: tokenInfo?.title ?? externalAddress,
      coins: [coinInWallet],
      totalAmount: tokenAmount,
      totalBalanceUSD: amountUSD,
    );

    Logger.info(
      '[TokenTransactionService] ✗ Using minimal token coin (${isFirstBuy ? 'first buy' : 'fallback'}): ${minimalCoin.id}',
    );

    return (coin: minimalCoin, coinsGroup: coinsGroup);
  }

  ({
    String paymentRawAmount,
    double tokenAmount,
    String tokenRawAmount,
    double amountUSD,
  }) _calculateAmounts({
    required double amount,
    required CoinData paymentToken,
    required PricingResponse expectedPricing,
  }) {
    final paymentRawAmount = toBlockchainUnits(amount, paymentToken.decimals).toString();
    const tokenDecimals = TokenizedCommunitiesConstants.creatorTokenDecimals;
    final tokenAmount = fromBlockchainUnits(
      expectedPricing.amount,
      tokenDecimals,
    );
    final tokenRawAmount = expectedPricing.amount;
    final amountUSD = expectedPricing.amountUSD;

    return (
      paymentRawAmount: paymentRawAmount,
      tokenAmount: tokenAmount,
      tokenRawAmount: tokenRawAmount,
      amountUSD: amountUSD,
    );
  }

  // Creates two transactions for a token buy operation:
  // 1. Payment transaction (send) - represents sending the payment token (e.g., USDT, BNB)
  // 2. Token transaction (receive) - represents receiving the token (creator token or content token)
  // Both transactions share the same txHash as they're part of the same blockchain swap transaction.
  // This dual-transaction approach allows the wallet to properly track:
  // - Outgoing payment token balance
  // - Incoming token balance
  // - Transaction history filtered by asset type or transaction type (send/receive)
  List<TransactionDetails> _createTransactions({
    required String? transactionId,
    required String txHash,
    required Wallet wallet,
    required WalletViewData walletView,
    required NetworkData network,
    required CoinData paymentToken,
    required CoinsGroup? paymentCoinsGroup,
    required double paymentAmount,
    required CoinData tokenCoin,
    required CoinsGroup tokenCoinsGroup,
    required ({
      String paymentRawAmount,
      double tokenAmount,
      String tokenRawAmount,
      double amountUSD,
    }) amounts,
  }) {
    const status = TransactionStatus.broadcasted;
    final dateRequested = DateTime.now();

    final paymentTransaction = _createPaymentTransaction(
      transactionId: transactionId,
      txHash: txHash,
      wallet: wallet,
      walletView: walletView,
      network: network,
      paymentToken: paymentToken,
      paymentCoinsGroup: paymentCoinsGroup,
      paymentAmount: paymentAmount,
      amounts: amounts,
      status: status,
      dateRequested: dateRequested,
    );

    final tokenTransaction = _createTokenTransaction(
      transactionId: transactionId,
      txHash: txHash,
      wallet: wallet,
      walletView: walletView,
      network: network,
      tokenCoin: tokenCoin,
      tokenCoinsGroup: tokenCoinsGroup,
      amounts: amounts,
      status: status,
      dateRequested: dateRequested,
    );

    _logTransactions(
      paymentTransaction: paymentTransaction,
      tokenTransaction: tokenTransaction,
      tokenCoin: tokenCoin,
    );

    return [paymentTransaction, tokenTransaction];
  }

  TransactionDetails _createPaymentTransaction({
    required String? transactionId,
    required String txHash,
    required Wallet wallet,
    required WalletViewData walletView,
    required NetworkData network,
    required CoinData paymentToken,
    required CoinsGroup? paymentCoinsGroup,
    required double paymentAmount,
    required ({
      String paymentRawAmount,
      double tokenAmount,
      String tokenRawAmount,
      double amountUSD,
    }) amounts,
    required TransactionStatus status,
    required DateTime dateRequested,
  }) {
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
          amount: paymentAmount,
          rawAmount: amounts.paymentRawAmount,
          balanceUSD: amounts.amountUSD,
          walletId: wallet.id,
        );

    final paymentAssetData = CryptoAssetToSendData.coin(
      coinsGroup: paymentTokenCoinsGroup,
      amount: paymentAmount,
      rawAmount: amounts.paymentRawAmount,
      amountUSD: amounts.amountUSD,
      selectedOption: paymentSelectedOption,
    );

    return TransactionDetails(
      id: transactionId,
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
  }

  TransactionDetails _createTokenTransaction({
    required String? transactionId,
    required String txHash,
    required Wallet wallet,
    required WalletViewData walletView,
    required NetworkData network,
    required CoinData tokenCoin,
    required CoinsGroup tokenCoinsGroup,
    required ({
      String paymentRawAmount,
      double tokenAmount,
      String tokenRawAmount,
      double amountUSD,
    }) amounts,
    required TransactionStatus status,
    required DateTime dateRequested,
  }) {
    final tokenSelectedOption = tokenCoinsGroup.coins.firstWhereOrNull(
          (coin) => coin.coin.id == tokenCoin.id,
        ) ??
        CoinInWalletData(
          coin: tokenCoin,
          amount: amounts.tokenAmount,
          rawAmount: amounts.tokenRawAmount,
          balanceUSD: amounts.amountUSD,
          walletId: wallet.id,
        );

    final tokenAssetData = CryptoAssetToSendData.coin(
      coinsGroup: tokenCoinsGroup,
      amount: amounts.tokenAmount,
      rawAmount: amounts.tokenRawAmount,
      amountUSD: amounts.amountUSD,
      selectedOption: tokenSelectedOption,
    );

    return TransactionDetails(
      id: transactionId,
      txHash: txHash,
      network: network,
      type: TransactionType.receive,
      assetData: tokenAssetData,
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
  }

  void _logTransactions({
    required TransactionDetails paymentTransaction,
    required TransactionDetails tokenTransaction,
    required CoinData tokenCoin,
  }) {
    Logger.info(
      '[TokenTransactionService] \n'
      'Payment Transaction:\n'
      '  txHash: ${paymentTransaction.txHash}\n'
      '  type: ${paymentTransaction.type.value}\n'
      '  coinId: ${paymentTransaction.assetData.mapOrNull(coin: (c) => c.selectedOption?.coin.id)}\n'
      '  coinName: ${paymentTransaction.assetData.mapOrNull(coin: (c) => c.coinsGroup.name)}\n'
      '  amount: ${paymentTransaction.assetData.mapOrNull(coin: (c) => c.amount)}\n'
      '  status: ${paymentTransaction.status.toJson()}\n'
      '  walletViewId: ${paymentTransaction.walletViewId}\n'
      'Token Transaction:\n'
      '  txHash: ${tokenTransaction.txHash}\n'
      '  type: ${tokenTransaction.type.value}\n'
      '  coinId: ${tokenTransaction.assetData.mapOrNull(coin: (c) => c.selectedOption?.coin.id)}\n'
      '  coinName: ${tokenTransaction.assetData.mapOrNull(coin: (c) => c.coinsGroup.name)}\n'
      '  amount: ${tokenTransaction.assetData.mapOrNull(coin: (c) => c.amount)}\n'
      '  status: ${tokenTransaction.status.toJson()}\n'
      '  walletViewId: ${tokenTransaction.walletViewId}\n'
      'Token Coin Details:\n'
      '  coinId: ${tokenCoin.id}\n'
      '  contractAddress: ${tokenCoin.contractAddress}\n'
      '  symbolGroup: ${tokenCoin.symbolGroup}\n'
      '  abbreviation: ${tokenCoin.abbreviation}\n',
    );
  }

  Future<void> _saveTransactions(List<TransactionDetails> transactions) async {
    final transactionsRepository = await _ref.read(transactionsRepositoryProvider.future);

    await Future.wait(
      transactions.map(transactionsRepository.saveTransactionDetails),
    );

    Logger.info(
      '[TokenTransactionService] Successfully saved ${transactions.length} pending transactions',
    );
  }
}

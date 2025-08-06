// SPDX-License-Identifier: ice License 1.0

part of 'wallet_views_service.r.dart';

/// Wrapper class to enable combining streams of different types using combineLatestAll
class _StreamResult {
  const _StreamResult.coinTransactions(this.coinTransactions)
      : nftTransactions = const [],
        coins = const [];

  const _StreamResult.nftTransactions(this.nftTransactions)
      : coinTransactions = const {},
        coins = const [];

  const _StreamResult.coins(this.coins)
      : coinTransactions = const {},
        nftTransactions = const [];

  final Map<CoinData, List<TransactionData>> coinTransactions;
  final List<TransactionData> nftTransactions;
  final List<CoinData> coins;
}

@riverpod
Future<WalletViewsLiveUpdater> walletViewsLiveUpdater(Ref ref) async {
  final (transactionsRepo, userWallets) = await (
    ref.watch(transactionsRepositoryProvider.future),
    ref.watch(walletsNotifierProvider.future),
  ).wait;

  return WalletViewsLiveUpdater(
    transactionsRepo,
    ref.watch(coinsRepositoryProvider),
    userWallets,
  );
}

class WalletViewsLiveUpdater {
  WalletViewsLiveUpdater(
    this._transactionsRepository,
    this._coinsRepository,
    this._userWallets,
  );

  final TransactionsRepository _transactionsRepository;
  final CoinsRepository _coinsRepository;
  final List<Wallet> _userWallets;

  /// Watches for live updates to wallet views.
  /// Returns a stream of fully updated wallet views.
  Stream<List<WalletViewData>> watchWalletViews(
    List<WalletViewData> walletViews,
  ) async* {
    if (walletViews.isEmpty) {
      Logger.error(
        '[WalletViewsLiveUpdater]: No wallet views to watch, returning empty stream',
      );
      return;
    }

    final coinIds = _extractCoinIds(walletViews);
    final hasNfts = _hasNfts(walletViews);

    Logger.info(
      '[WalletViewsLiveUpdater] Starting to watch ${coinIds.length} coins and ${hasNfts ? 'NFTs' : 'no NFTs'} for updates',
    );

    if (coinIds.isEmpty && !hasNfts) {
      Logger.info('[WalletViewsLiveUpdater] No coins or NFTs to watch, returning empty stream');
      return;
    }

    final coinTransactionsStream = _createCoinTransactionsStream(coinIds);
    final nftTransactionsStream = _createNftTransactionsStream(walletViews);
    final coinsStream = _createCoinsStream(coinIds);

    await for (final update in _combineStreams(
      coinTransactionsStream,
      nftTransactionsStream,
      coinsStream,
    )) {
      yield _applyWalletViewUpdates(walletViews, update);
    }
  }

  Future<List<WalletViewData>> applyFiltering(List<WalletViewData> walletViews) async {
    if (walletViews.isEmpty) {
      return walletViews;
    }

    final coinIds = _extractCoinIds(walletViews);
    final hasNfts = _hasNfts(walletViews);

    if (coinIds.isEmpty && !hasNfts) {
      return walletViews;
    }

    final coinTransactions = await _createCoinTransactionsStream(coinIds).first;
    final nftTransactions = await _createNftTransactionsStream(walletViews).first;
    final updatedCoins = await _createCoinsStream(coinIds).first;

    final update = WalletViewUpdate(
      coinTransactions: coinTransactions,
      nftTransactions: nftTransactions,
      updatedCoins: updatedCoins,
    );

    return _applyWalletViewUpdates(walletViews, update);
  }

  Set<String> _extractCoinIds(List<WalletViewData> walletViews) {
    return walletViews
        .expand((view) => view.coinGroups)
        .expand((group) => group.coins)
        .map((coin) => coin.coin.id)
        .toSet();
  }

  bool _hasNfts(List<WalletViewData> walletViews) =>
      walletViews.any((view) => view.nfts.isNotEmpty);

  List<NftIdentifier> _extractNftIdentifiers(List<WalletViewData> walletViews) {
    return walletViews.expand((view) => view.nfts).map((nft) => nft.identifier).toList();
  }

  Stream<Map<CoinData, List<TransactionData>>> _createCoinTransactionsStream(Set<String> coinIds) {
    if (coinIds.isEmpty) {
      return Stream.value(<CoinData, List<TransactionData>>{});
    }

    return _transactionsRepository.watchBroadcastedTransfersByCoins(coinIds.toList()).map(
          (transactions) => Map.fromEntries(
            transactions.entries.where((e) => e.key.network.tier == 1),
          ),
        );
  }

  Stream<List<TransactionData>> _createNftTransactionsStream(List<WalletViewData> walletViews) {
    final nftIdentifiers = _extractNftIdentifiers(walletViews);

    if (nftIdentifiers.isEmpty) {
      return Stream.value(<TransactionData>[]);
    }

    return _transactionsRepository
        .watchTransactions(
          type: TransactionType.send,
          assetType: CryptoAssetType.nft,
          nftIdentifiers: nftIdentifiers,
          statuses: TransactionStatus.inProgressStatuses,
        )
        .map((transactions) => transactions.where((tx) => tx.network.tier == 1).toList());
  }

  Stream<List<CoinData>> _createCoinsStream(Set<String> coinIds) {
    if (coinIds.isEmpty) {
      return Stream.value(<CoinData>[]);
    }
    return _coinsRepository.watchCoins(coinIds);
  }

  Stream<WalletViewUpdate> _combineStreams(
    Stream<Map<CoinData, List<TransactionData>>> coinTransactionsStream,
    Stream<List<TransactionData>> nftTransactionsStream,
    Stream<List<CoinData>> coinsStream,
  ) async* {

    // Wrap each stream to enable combineLatestAll
    final wrappedCoinTransactions = coinTransactionsStream.map(_StreamResult.coinTransactions);

    final wrappedNftTransactions = nftTransactionsStream.map(_StreamResult.nftTransactions);

    final wrappedCoins = coinsStream.map(_StreamResult.coins);

    await for (final results in wrappedCoinTransactions
        .combineLatestAll([
          wrappedNftTransactions,
          wrappedCoins,
        ])
        .map(
          (streamResults) => (
            coinTransactions: streamResults[0].coinTransactions,
            nftTransactions: streamResults[1].nftTransactions,
            coins: streamResults[2].coins,
          ),
        )
        .distinct((prev, current) {
          // Enhanced comparison for coin transactions
          final coinTxsEqual =
              _compareTransactionMaps(prev.coinTransactions, current.coinTransactions);
          final nftTxsEqual =
              _compareTransactionLists(prev.nftTransactions, current.nftTransactions);
          final coinsEqual = _compareCoinLists(prev.coins, current.coins);

          return !(coinTxsEqual && nftTxsEqual && coinsEqual);
        })
        .debounce(const Duration(milliseconds: 300))) {

      yield WalletViewUpdate(
        updatedCoins: results.coins,
        coinTransactions: results.coinTransactions,
        nftTransactions: results.nftTransactions,
      );
    }
  }

  List<WalletViewData> _applyWalletViewUpdates(
    List<WalletViewData> views,
    WalletViewUpdate update,
  ) {
    // Log USDT balances before applying updates
    _logUsdtBalances(views, '[WalletViewsLiveUpdater] Before applying updates');

    final updatedViews = views.map((walletView) {
      final updatedGroups = walletView.coinGroups.map((group) {
        var totalGroupAmount = 0.0;
        var totalGroupBalanceUSD = 0.0;

        final updatedCoinsInGroup = group.coins.map((coinInWallet) {

          var modifiedCoin = _applyUpdatedCoinPrice(
            coinInWallet: coinInWallet,
            updatedCoins: update.updatedCoins,
          );


          final beforeTransactions = modifiedCoin.amount;
          modifiedCoin = _applyExecutingTransactions(
            coinInWallet: modifiedCoin,
            transactions: update.coinTransactions,
            walletViewId: walletView.id,
          );


          totalGroupAmount += modifiedCoin.amount;
          totalGroupBalanceUSD += modifiedCoin.balanceUSD;

          return modifiedCoin;
        }).toList();


        return group.copyWith(
          coins: updatedCoinsInGroup,
          totalAmount: totalGroupAmount,
          totalBalanceUSD: totalGroupBalanceUSD,
        );
      }).toList();

      // Apply NFT filtering for broadcasted transactions
      final filteredNfts = _applyExecutingNftTransactions(
        nfts: walletView.nfts,
        transactions: update.nftTransactions,
        walletViewId: walletView.id,
      );

      final updatedWalletView = walletView.copyWith(
        coinGroups: updatedGroups,
        nfts: filteredNfts,
        usdBalance: updatedGroups.fold(0, (sum, group) => sum + group.totalBalanceUSD),
      );

      return updatedWalletView;
    }).toList();

    // Log USDT balances after applying updates
    _logUsdtBalances(updatedViews, '[WalletViewsLiveUpdater] After applying updates');

    return updatedViews;
  }

  CoinInWalletData _applyUpdatedCoinPrice({
    required Iterable<CoinData> updatedCoins,
    required CoinInWalletData coinInWallet,
  }) {
    if (updatedCoins.isNotEmpty) {
      final updatedCoin = updatedCoins.firstWhereOrNull(
        (coin) => coin.id == coinInWallet.coin.id,
      );

      if (updatedCoin != null) {
        final balanceUSD = coinInWallet.amount * updatedCoin.priceUSD;
        return coinInWallet.copyWith(
          coin: updatedCoin,
          balanceUSD: balanceUSD,
        );
      }
    }

    return coinInWallet;
  }

  /// Subtracts sent coins from the existing number of coins.
  CoinInWalletData _applyExecutingTransactions({
    required String walletViewId,
    required CoinInWalletData coinInWallet,
    required Map<CoinData, List<TransactionData>> transactions,
  }) {
    var updatedCoin = coinInWallet;
    final isUsdtCoin = coinInWallet.coin.abbreviation.toUpperCase() == 'USDT';

    if (transactions.isEmpty) {
      return updatedCoin;
    }

    final key = transactions.keys.firstWhereOrNull(
      (key) => key.id == coinInWallet.coin.id,
    );

    if (key == null) {
      return updatedCoin;
    }

    final coinTransactions = transactions[key] ?? [];

    final wallet = _userWallets.firstWhereOrNull(
      (w) => w.id == coinInWallet.walletId,
    );

    if (wallet == null) {
      return updatedCoin;
    }

    if (isUsdtCoin) {
      Logger.info('[WalletViewsLiveUpdater] USDT Transaction Processing - Original amount: ${coinInWallet.amount}, Network: ${coinInWallet.coin.network.displayName}, Transactions: ${coinTransactions.length}');
    }

    var adjustedRawAmount = BigInt.parse(coinInWallet.rawAmount);
    var balanceHackApplied = false;
    var totalReduction = BigInt.zero;

    for (final transaction in coinTransactions) {
      final isTransactionRelatedToCoin = transaction.senderWalletAddress == wallet.address;
      final isTransactionRelatedToWalletView = transaction.walletViewId == walletViewId;
      final transactionCoin = transaction.cryptoAsset;

      if (isTransactionRelatedToCoin &&
          transactionCoin is CoinTransactionAsset &&
          isTransactionRelatedToWalletView) {
        final reductionAmount = BigInt.parse(transactionCoin.rawAmount);
        adjustedRawAmount -= reductionAmount;
        totalReduction += reductionAmount;
        balanceHackApplied = true;

        if (isUsdtCoin) {
          Logger.info('[WalletViewsLiveUpdater] USDT Transaction Applied - TxHash: ${transaction.txHash}, Reduction: ${transactionCoin.amount}, Status: ${transaction.status}');
        }
      }
    }

    final adjustedAmount = parseCryptoAmount(
      (adjustedRawAmount.isNegative ? 0 : adjustedRawAmount).toString(),
      coinInWallet.coin.decimals,
    );
    final adjustedBalanceUSD = adjustedAmount * coinInWallet.coin.priceUSD;

    updatedCoin = coinInWallet.copyWith(
      amount: adjustedAmount,
      balanceUSD: adjustedBalanceUSD,
      rawAmount: adjustedRawAmount.toString(),
    );

    if (isUsdtCoin && balanceHackApplied) {
      Logger.info('[WalletViewsLiveUpdater] USDT Transaction Result - Original: ${coinInWallet.amount}, Adjusted: ${adjustedAmount}, Total Reduction: ${parseCryptoAmount(totalReduction.toString(), coinInWallet.coin.decimals)}, Network: ${coinInWallet.coin.network.displayName}');
    }

    return updatedCoin;
  }

  /// Filters out NFTs that have been sent and are still in-progress (pending, executing, broadcasted).
  List<NftData> _applyExecutingNftTransactions({
    required String walletViewId,
    required List<NftData> nfts,
    required List<TransactionData> transactions,
  }) {
    if (transactions.isEmpty) {
      Logger.info(
        '[WalletViewsLiveUpdater] No NFT transactions to filter for wallet view $walletViewId, returning ${nfts.length} NFTs unchanged',
      );
      return nfts;
    }

    final walletAddressMap = <String, Wallet>{
      for (final wallet in _userWallets)
        if (wallet.address != null) wallet.address!: wallet,
    };

    final nftIdentifiersToExclude = <NftIdentifier>{};

    for (final transaction in transactions) {
      final wallet = walletAddressMap[transaction.senderWalletAddress];

      // Skip transaction if not from a user wallet or not related to current wallet view
      if (wallet == null || transaction.walletViewId != walletViewId) {
        continue;
      }

      final transactionNft = transaction.cryptoAsset;
      final isNftTransaction =
          transactionNft is NftTransactionAsset || transactionNft is NftIdentifierTransactionAsset;

      if (isNftTransaction) {
        final transactionNftIdentifier = switch (transactionNft) {
          NftTransactionAsset(nft: final nft) => nft.identifier,
          NftIdentifierTransactionAsset(nftIdentifier: final identifier) => identifier,
          _ => null,
        };

        if (transactionNftIdentifier != null) {
          nftIdentifiersToExclude.add(transactionNftIdentifier);
        }
      }
    }

    final filteredNfts =
        nfts.where((nft) => !nftIdentifiersToExclude.contains(nft.identifier)).toList();

    if (filteredNfts.isNotEmpty) {
      Logger.info(
        '[WalletViewsLiveUpdater] Filtered NFTs: \n${filteredNfts.map((nft) => 'Name: ${nft.name} | ID: ${nft.identifier.value} | Contract: ${nft.contract} | TokenId: ${nft.tokenId} | Symbol: ${nft.symbol}').join('\n')}',
      );
    }

    return filteredNfts;
  }

  /// Enhanced comparison for transaction maps that includes transaction metadata
  bool _compareTransactionMaps(
    Map<CoinData, List<TransactionData>> map1,
    Map<CoinData, List<TransactionData>> map2,
  ) {
    if (map1.length != map2.length) return false;

    for (final entry in map1.entries) {
      final coin = entry.key;
      final txs1 = entry.value;
      final txs2 = map2[coin];

      if (txs2 == null || !_compareTransactionLists(txs1, txs2)) {
        return false;
      }
    }

    return true;
  }

  /// Enhanced comparison for transaction lists that includes status, timestamps, and amounts
  bool _compareTransactionLists(List<TransactionData> list1, List<TransactionData> list2) {
    if (list1.length != list2.length) {
      return false;
    }

    for (int i = 0; i < list1.length; i++) {
      final tx1 = list1[i];
      final tx2 = list2[i];

      // Compare transaction hash, status, amount, and key metadata
      if (tx1.txHash != tx2.txHash ||
          tx1.status != tx2.status ||
          tx1.senderWalletAddress != tx2.senderWalletAddress ||
          tx1.walletViewId != tx2.walletViewId) {
        return false;
      }

      // Compare crypto asset details
      final asset1 = tx1.cryptoAsset;
      final asset2 = tx2.cryptoAsset;

      if (asset1.runtimeType != asset2.runtimeType) {
        return false;
      }

      if (asset1 is CoinTransactionAsset && asset2 is CoinTransactionAsset) {
        if (asset1.amount != asset2.amount ||
            asset1.rawAmount != asset2.rawAmount ||
            asset1.coin.id != asset2.coin.id) {
          return false;
        }
      }
    }

    return true;
  }

  /// Enhanced comparison for coin lists that includes prices and metadata
  bool _compareCoinLists(List<CoinData> list1, List<CoinData> list2) {
    if (list1.length != list2.length) {
      return false;
    }

    for (int i = 0; i < list1.length; i++) {
      final coin1 = list1[i];
      final coin2 = list2[i];

      if (coin1.id != coin2.id ||
          coin1.priceUSD != coin2.priceUSD ||
          coin1.name != coin2.name ||
          coin1.abbreviation != coin2.abbreviation) {
        return false;
      }
    }

    return true;
  }

  /// Generates a signature for a transaction including key properties that affect balance
  String _generateTransactionSignature(TransactionData transaction) {
    final asset = transaction.cryptoAsset;
    String assetSignature = '';

    if (asset is CoinTransactionAsset) {
      assetSignature = '${asset.coin.id}:${asset.amount}:${asset.rawAmount}';
    } else if (asset is NftTransactionAsset) {
      assetSignature = 'nft:${asset.nft.identifier.value}';
    } else if (asset is NftIdentifierTransactionAsset) {
      assetSignature = 'nft_id:${asset.nftIdentifier.value}';
    }

    return '${transaction.status}:${transaction.senderWalletAddress}:${transaction.walletViewId}:$assetSignature';
  }

  void _logUsdtBalances(List<WalletViewData> walletViews, String context) {
    for (final walletView in walletViews) {
      for (final coinGroup in walletView.coinGroups) {
        if (coinGroup.symbolGroup.toUpperCase() == 'USDT' && coinGroup.totalAmount > 0) {
          final networksWithBalance = <String>[];
          for (final coinInWallet in coinGroup.coins) {
            if (coinInWallet.amount > 0) {
              networksWithBalance.add('${coinInWallet.coin.network.displayName}: ${coinInWallet.amount}');
            }
          }
          Logger.info('$context - USDT Total: ${coinGroup.totalAmount}, Networks: [${networksWithBalance.join(', ')}], WalletView: ${walletView.id}');
        }
      }
    }
  }
}

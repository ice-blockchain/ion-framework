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

  // Cache to prevent repeated processing of same transactions
  final Map<String, Map<String, String>> _processedTransactions = {};
  // Key format: "walletViewId:coinId" -> Map<txHash, txSignature>
  // txSignature includes status, amount, and other key properties

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
    Logger.info(
        '[WalletViewsLiveUpdater] _combineStreams starting - setting up stream combination');

    // Wrap each stream to enable combineLatestAll
    final wrappedCoinTransactions = coinTransactionsStream.map((data) {
      Logger.info(
          '[WalletViewsLiveUpdater] Coin transactions stream update: ${data.length} transaction groups');
      for (final entry in data.entries) {
        final coin = entry.key;
        final txs = entry.value;
        Logger.info(
            '[WalletViewsLiveUpdater]   - ${coin.abbreviation}: ${txs.length} transactions');
      }
      return _StreamResult.coinTransactions(data);
    });

    final wrappedNftTransactions = nftTransactionsStream.map((data) {
      Logger.info(
          '[WalletViewsLiveUpdater] NFT transactions stream update: ${data.length} transactions');
      return _StreamResult.nftTransactions(data);
    });

    final wrappedCoins = coinsStream.map((data) {
      Logger.info('[WalletViewsLiveUpdater] Coins stream update: ${data.length} coins');
      for (final coin in data) {
        Logger.info(
            '[WalletViewsLiveUpdater]   - ${coin.abbreviation}: \$${coin.priceUSD.toStringAsFixed(6)}');
      }
      return _StreamResult.coins(data);
    });

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

          final isDistinct = !(coinTxsEqual && nftTxsEqual && coinsEqual);

          if (isDistinct) {
            Logger.info(
                '[WalletViewsLiveUpdater] Stream data changed - passing through distinct filter:');
            Logger.info('[WalletViewsLiveUpdater]   - Coin transactions changed: ${!coinTxsEqual}');
            Logger.info('[WalletViewsLiveUpdater]   - NFT transactions changed: ${!nftTxsEqual}');
            Logger.info('[WalletViewsLiveUpdater]   - Coins changed: ${!coinsEqual}');

            if (!coinTxsEqual) {
              _logTransactionMapDifferences(prev.coinTransactions, current.coinTransactions);
            }
          } else {
            Logger.info(
                '[WalletViewsLiveUpdater] Stream data unchanged - filtered out by distinct');
          }

          return !isDistinct;
        })
        .debounce(const Duration(milliseconds: 300))) {
      final timestamp = DateTime.now();
      Logger.info(
        '[WalletViewsLiveUpdater] Emitting update at $timestamp - ${results.coins.length} coins, '
        '${results.coinTransactions.length} coin transactions, '
        '${results.nftTransactions.length} NFT transactions',
      );

      // Log detailed coin information
      for (final coin in results.coins) {
        Logger.info(
            '[WalletViewsLiveUpdater] Updated coin: ${coin.abbreviation} (${coin.name}) - Price: \$${coin.priceUSD.toStringAsFixed(6)} on ${coin.network.displayName}');
      }

      // Log transaction details
      for (final entry in results.coinTransactions.entries) {
        final coin = entry.key;
        final transactions = entry.value;
        Logger.info(
            '[WalletViewsLiveUpdater] ${transactions.length} transactions for ${coin.abbreviation}:');
        for (final tx in transactions) {
          final asset = tx.cryptoAsset;
          if (asset is CoinTransactionAsset) {
            Logger.info(
                '[WalletViewsLiveUpdater]   - ${tx.txHash}: ${asset.amount} ${coin.abbreviation} (${tx.status}) from ${tx.senderWalletAddress}');
          }
        }
      }

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
    final timestamp = DateTime.now();
    Logger.info(
        '[WalletViewsLiveUpdater] _applyWalletViewUpdates called at $timestamp for ${views.length} wallet views');
    Logger.info(
        '[WalletViewsLiveUpdater] Update contains: ${update.updatedCoins.length} coins, ${update.coinTransactions.length} coin transaction groups, ${update.nftTransactions.length} NFT transactions');

    // Clean up transaction cache to prevent memory leaks
    _cleanupTransactionCache(views);

    return views.map((walletView) {
      Logger.info(
          '[WalletViewsLiveUpdater] Processing wallet view ${walletView.id} (${walletView.name})');

      // Log original balances
      for (final group in walletView.coinGroups) {
        Logger.info(
            '[WalletViewsLiveUpdater] Original balance for ${group.symbolGroup}: ${group.totalAmount} (USD: \$${group.totalBalanceUSD.toStringAsFixed(2)})');
      }
      final updatedGroups = walletView.coinGroups.map((group) {
        Logger.info('[WalletViewsLiveUpdater] Processing coin group ${group.symbolGroup}');
        var totalGroupAmount = 0.0;
        var totalGroupBalanceUSD = 0.0;

        final updatedCoinsInGroup = group.coins.map((coinInWallet) {
          Logger.info(
              '[WalletViewsLiveUpdater] Processing coin ${coinInWallet.coin.abbreviation} in group ${group.symbolGroup}');
          Logger.info('[WalletViewsLiveUpdater]   - Original amount: ${coinInWallet.amount}');

          var modifiedCoin = _applyUpdatedCoinPrice(
            coinInWallet: coinInWallet,
            updatedCoins: update.updatedCoins,
          );

          if (modifiedCoin.amount != coinInWallet.amount) {
            Logger.info(
                '[WalletViewsLiveUpdater]   - After price update: ${modifiedCoin.amount} (price changed)');
          }

          final beforeTransactions = modifiedCoin.amount;
          modifiedCoin = _applyExecutingTransactions(
            coinInWallet: modifiedCoin,
            transactions: update.coinTransactions,
            walletViewId: walletView.id,
          );

          if (modifiedCoin.amount != beforeTransactions) {
            Logger.info(
                '[WalletViewsLiveUpdater]   - After transaction processing: ${modifiedCoin.amount} (was $beforeTransactions)');
          }

          totalGroupAmount += modifiedCoin.amount;
          totalGroupBalanceUSD += modifiedCoin.balanceUSD;

          Logger.info('[WalletViewsLiveUpdater]   - Final amount: ${modifiedCoin.amount}');
          Logger.info('[WalletViewsLiveUpdater]   - Running group total: $totalGroupAmount');

          return modifiedCoin;
        }).toList();

        Logger.info('[WalletViewsLiveUpdater] Group ${group.symbolGroup} processing complete:');
        Logger.info('[WalletViewsLiveUpdater]   - Original total: ${group.totalAmount}');
        Logger.info('[WalletViewsLiveUpdater]   - New total: $totalGroupAmount');
        Logger.info(
            '[WalletViewsLiveUpdater]   - Balance changed: ${totalGroupAmount != group.totalAmount}');

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

      // Log updated balances
      for (final group in updatedWalletView.coinGroups) {
        Logger.info(
            '[WalletViewsLiveUpdater] Updated balance for ${group.symbolGroup}: ${group.totalAmount} (USD: \$${group.totalBalanceUSD.toStringAsFixed(2)})');
      }

      return updatedWalletView;
    }).toList();
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
    final timestamp = DateTime.now();
    Logger.info(
        '[WalletViewsLiveUpdater] _applyExecutingTransactions called at $timestamp for ${coinInWallet.coin.abbreviation} in wallet view $walletViewId');
    Logger.info(
        '[WalletViewsLiveUpdater] Initial balance: ${coinInWallet.amount} ${coinInWallet.coin.abbreviation} (Raw: ${coinInWallet.rawAmount})');

    var updatedCoin = coinInWallet;

    if (transactions.isEmpty) {
      Logger.info(
          '[WalletViewsLiveUpdater] No transactions provided - returning original balance: ${coinInWallet.amount} ${coinInWallet.coin.abbreviation}');
      return updatedCoin;
    }

    Logger.info('[WalletViewsLiveUpdater] Processing ${transactions.length} transaction groups');

    final key = transactions.keys.firstWhereOrNull(
      (key) => key.id == coinInWallet.coin.id,
    );

    if (key == null) {
      Logger.info(
          '[WalletViewsLiveUpdater] No transactions found for coin ${coinInWallet.coin.id} (${coinInWallet.coin.abbreviation}) - returning original balance');
      return updatedCoin;
    }

    final coinTransactions = transactions[key] ?? [];
    Logger.info(
        '[WalletViewsLiveUpdater] Found ${coinTransactions.length} transactions for coin ${coinInWallet.coin.abbreviation}');

    final wallet = _userWallets.firstWhereOrNull(
      (w) => w.id == coinInWallet.walletId,
    );

    if (wallet == null) {
      Logger.info(
          '[WalletViewsLiveUpdater] Wallet not found for walletId: ${coinInWallet.walletId} - returning original balance');
      return updatedCoin;
    }

    Logger.info(
        '[WalletViewsLiveUpdater] Found wallet ${wallet.id} with address: ${wallet.address}');

    var adjustedRawAmount = BigInt.parse(coinInWallet.rawAmount);
    Logger.info('[WalletViewsLiveUpdater] Starting raw amount: $adjustedRawAmount');

    if (coinTransactions.isNotEmpty) {
      Logger.info(
        '[WalletViewsLiveUpdater] Apply broadcasted transactions(${coinTransactions.length}) '
        'for ${coinInWallet.coin.abbreviation}(${coinInWallet.coin.name}). '
        'Network: ${coinInWallet.coin.network.id}. Initial balance: ${coinInWallet.amount}.',
      );
    }

    var balanceHackApplied = false;
    var totalReduction = BigInt.zero;

    final cacheKey = '$walletViewId:${coinInWallet.coin.id}';
    final currentTransactionSignatures = <String, String>{};

    // Generate signatures for current transactions
    for (final transaction in coinTransactions) {
      final signature = _generateTransactionSignature(transaction);
      currentTransactionSignatures[transaction.txHash] = signature;
    }

    // Check if we've already processed these exact transactions
    final previousSignatures = _processedTransactions[cacheKey] ?? <String, String>{};
    final signaturesEqual = const MapEquality<String, String>().equals(
      previousSignatures,
      currentTransactionSignatures,
    );

    if (signaturesEqual && currentTransactionSignatures.isNotEmpty) {
      Logger.info(
          '[WalletViewsLiveUpdater] 🔄 TRANSACTION CACHE HIT - Same transactions already processed for $cacheKey');
      Logger.info(
          '[WalletViewsLiveUpdater] Transactions: ${currentTransactionSignatures.keys.join(', ')}');
      Logger.info(
          '[WalletViewsLiveUpdater] Skipping repeated processing - returning original balance: ${coinInWallet.amount}');
      return updatedCoin;
    }

    // Update cache with current transaction signatures
    _processedTransactions[cacheKey] = currentTransactionSignatures;
    Logger.info(
        '[WalletViewsLiveUpdater] 🆕 TRANSACTION CACHE MISS - Processing new/changed transactions for $cacheKey');

    for (final transaction in coinTransactions) {
      Logger.info('[WalletViewsLiveUpdater] Processing transaction ${transaction.txHash}:');
      Logger.info('[WalletViewsLiveUpdater]   - Status: ${transaction.status}');
      Logger.info('[WalletViewsLiveUpdater]   - Sender: ${transaction.senderWalletAddress}');
      Logger.info('[WalletViewsLiveUpdater]   - Wallet Address: ${wallet.address}');
      Logger.info('[WalletViewsLiveUpdater]   - WalletViewId: ${transaction.walletViewId}');
      Logger.info('[WalletViewsLiveUpdater]   - Target WalletViewId: $walletViewId');

      final isTransactionRelatedToCoin = transaction.senderWalletAddress == wallet.address;
      final isTransactionRelatedToWalletView = transaction.walletViewId == walletViewId;
      final transactionCoin = transaction.cryptoAsset;

      Logger.info('[WalletViewsLiveUpdater]   - Related to coin: $isTransactionRelatedToCoin');
      Logger.info(
          '[WalletViewsLiveUpdater]   - Related to wallet view: $isTransactionRelatedToWalletView');
      Logger.info('[WalletViewsLiveUpdater]   - Crypto asset type: ${transactionCoin.runtimeType}');

      if (isTransactionRelatedToCoin &&
          transactionCoin is CoinTransactionAsset &&
          isTransactionRelatedToWalletView) {
        final reductionAmount = BigInt.parse(transactionCoin.rawAmount);
        adjustedRawAmount -= reductionAmount;
        totalReduction += reductionAmount;

        balanceHackApplied = true;
        Logger.info(
          '[WalletViewsLiveUpdater] ✓ APPLYING BALANCE REDUCTION: '
          'amount: ${transactionCoin.amount} (raw: ${transactionCoin.rawAmount}) '
          'txHash: ${transaction.txHash}, '
          'network: ${transaction.network.id}, '
          'coin: ${transactionCoin.coin.abbreviation}',
        );
        Logger.info('[WalletViewsLiveUpdater]   - Raw amount after reduction: $adjustedRawAmount');
      } else {
        Logger.info('[WalletViewsLiveUpdater] ✗ SKIPPING TRANSACTION (conditions not met)');
        if (!isTransactionRelatedToCoin) {
          Logger.info('[WalletViewsLiveUpdater]   - Reason: Transaction not from wallet address');
        }
        if (transactionCoin is! CoinTransactionAsset) {
          Logger.info('[WalletViewsLiveUpdater]   - Reason: Not a coin transaction asset');
        }
        if (!isTransactionRelatedToWalletView) {
          Logger.info('[WalletViewsLiveUpdater]   - Reason: Transaction not for this wallet view');
        }
      }
    }

    final adjustedAmount = parseCryptoAmount(
      (adjustedRawAmount.isNegative ? 0 : adjustedRawAmount).toString(),
      coinInWallet.coin.decimals,
    );
    final adjustedBalanceUSD = adjustedAmount * coinInWallet.coin.priceUSD;

    Logger.info('[WalletViewsLiveUpdater] Balance calculation complete:');
    Logger.info('[WalletViewsLiveUpdater]   - Original amount: ${coinInWallet.amount}');
    Logger.info('[WalletViewsLiveUpdater]   - Total reduction (raw): $totalReduction');
    Logger.info('[WalletViewsLiveUpdater]   - Final raw amount: $adjustedRawAmount');
    Logger.info('[WalletViewsLiveUpdater]   - Final adjusted amount: $adjustedAmount');
    Logger.info('[WalletViewsLiveUpdater]   - Balance hack applied: $balanceHackApplied');

    if (adjustedAmount != coinInWallet.amount) {
      Logger.info(
          '[WalletViewsLiveUpdater] 🔄 BALANCE CHANGED from ${coinInWallet.amount} to $adjustedAmount ${coinInWallet.coin.abbreviation}');
    } else {
      Logger.info(
          '[WalletViewsLiveUpdater] ➡️  BALANCE UNCHANGED: ${coinInWallet.amount} ${coinInWallet.coin.abbreviation}');
    }

    if (adjustedAmount > 0 && balanceHackApplied) {
      Logger.info(
        '[WalletViewsLiveUpdater] The reduction is complete. Adjusted amount: $adjustedAmount',
      );
    }

    updatedCoin = coinInWallet.copyWith(
      amount: adjustedAmount,
      balanceUSD: adjustedBalanceUSD,
      rawAmount: adjustedRawAmount.toString(),
    );

    // Defensive balance state tracking
    final balanceChangeKey = '$walletViewId:${coinInWallet.coin.id}:balance';
    final expectedBalanceAfterReductions = coinInWallet.amount -
        (totalReduction.toDouble() / BigInt.from(10).pow(coinInWallet.coin.decimals).toDouble());

    // Check if the calculated balance matches expected balance after reductions
    if (balanceHackApplied &&
        (adjustedAmount - expectedBalanceAfterReductions).abs() > 0.000000001) {
      Logger.info('[WalletViewsLiveUpdater] ⚠️  BALANCE INCONSISTENCY DETECTED:');
      Logger.info('[WalletViewsLiveUpdater]   - Original balance: ${coinInWallet.amount}');
      Logger.info('[WalletViewsLiveUpdater]   - Total reduction (raw): $totalReduction');
      Logger.info('[WalletViewsLiveUpdater]   - Expected balance: $expectedBalanceAfterReductions');
      Logger.info('[WalletViewsLiveUpdater]   - Actual calculated: $adjustedAmount');
      Logger.info(
          '[WalletViewsLiveUpdater]   - Difference: ${adjustedAmount - expectedBalanceAfterReductions}');
    }

    // Log final balance state with cache key for tracking
    Logger.info('[WalletViewsLiveUpdater] 💰 FINAL BALANCE STATE for $balanceChangeKey:');
    Logger.info(
        '[WalletViewsLiveUpdater]   - Input: ${coinInWallet.amount} ${coinInWallet.coin.abbreviation}');
    Logger.info(
        '[WalletViewsLiveUpdater]   - Output: ${adjustedAmount} ${coinInWallet.coin.abbreviation}');
    Logger.info(
        '[WalletViewsLiveUpdater]   - Change: ${adjustedAmount - coinInWallet.amount} ${coinInWallet.coin.abbreviation}');
    Logger.info('[WalletViewsLiveUpdater]   - Transactions processed: ${coinTransactions.length}');

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
    if (map1.length != map2.length) {
      Logger.info(
          '[WalletViewsLiveUpdater] Transaction maps have different sizes: ${map1.length} vs ${map2.length}');
      return false;
    }

    for (final entry in map1.entries) {
      final coin = entry.key;
      final txs1 = entry.value;
      final txs2 = map2[coin];

      if (txs2 == null) {
        Logger.info('[WalletViewsLiveUpdater] Coin ${coin.abbreviation} not found in second map');
        return false;
      }

      if (!_compareTransactionLists(txs1, txs2)) {
        Logger.info(
            '[WalletViewsLiveUpdater] Transaction lists differ for coin ${coin.abbreviation}');
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

  /// Clears transaction cache for completed/confirmed transactions to prevent memory leaks
  void _cleanupTransactionCache(List<WalletViewData> walletViews) {
    final activeKeys = <String>{};

    // Collect all active cache keys from current wallet views
    for (final walletView in walletViews) {
      for (final group in walletView.coinGroups) {
        for (final coin in group.coins) {
          activeKeys.add('${walletView.id}:${coin.coin.id}');
        }
      }
    }

    // Remove cache entries for wallet views/coins that no longer exist
    final keysToRemove = _processedTransactions.keys
        .where((key) => !activeKeys.contains(key.split(':balance')[0]))
        .toList();

    if (keysToRemove.isNotEmpty) {
      Logger.info(
          '[WalletViewsLiveUpdater] 🧹 Cleaning up transaction cache: removing ${keysToRemove.length} old entries');
      for (final key in keysToRemove) {
        _processedTransactions.remove(key);
      }
    }
  }

  /// Logs detailed differences between transaction maps
  void _logTransactionMapDifferences(
    Map<CoinData, List<TransactionData>> prev,
    Map<CoinData, List<TransactionData>> current,
  ) {
    Logger.info('[WalletViewsLiveUpdater] Transaction map differences detected:');

    // Check for added/removed coins
    final prevCoins = prev.keys.toSet();
    final currentCoins = current.keys.toSet();

    final addedCoins = currentCoins.difference(prevCoins);
    final removedCoins = prevCoins.difference(currentCoins);
    final commonCoins = prevCoins.intersection(currentCoins);

    if (addedCoins.isNotEmpty) {
      Logger.info(
          '[WalletViewsLiveUpdater] Added coins: ${addedCoins.map((c) => c.abbreviation).join(', ')}');
    }
    if (removedCoins.isNotEmpty) {
      Logger.info(
          '[WalletViewsLiveUpdater] Removed coins: ${removedCoins.map((c) => c.abbreviation).join(', ')}');
    }

    // Check for changes in transaction lists for common coins
    for (final coin in commonCoins) {
      final prevTxs = prev[coin] ?? [];
      final currentTxs = current[coin] ?? [];

      if (prevTxs.length != currentTxs.length) {
        Logger.info(
            '[WalletViewsLiveUpdater] ${coin.abbreviation} transaction count changed: ${prevTxs.length} → ${currentTxs.length}');
      } else if (!_compareTransactionLists(prevTxs, currentTxs)) {
        Logger.info('[WalletViewsLiveUpdater] ${coin.abbreviation} transaction content changed:');

        for (int i = 0; i < prevTxs.length && i < currentTxs.length; i++) {
          final prevTx = prevTxs[i];
          final currentTx = currentTxs[i];

          if (prevTx.txHash != currentTx.txHash) {
            Logger.info(
                '[WalletViewsLiveUpdater]   [${i}] Hash: ${prevTx.txHash} → ${currentTx.txHash}');
          }
          if (prevTx.status != currentTx.status) {
            Logger.info(
                '[WalletViewsLiveUpdater]   [${i}] Status: ${prevTx.status} → ${currentTx.status}');
          }

          final prevAsset = prevTx.cryptoAsset;
          final currentAsset = currentTx.cryptoAsset;
          if (prevAsset is CoinTransactionAsset && currentAsset is CoinTransactionAsset) {
            if (prevAsset.amount != currentAsset.amount) {
              Logger.info(
                  '[WalletViewsLiveUpdater]   [${i}] Amount: ${prevAsset.amount} → ${currentAsset.amount}');
            }
            if (prevAsset.rawAmount != currentAsset.rawAmount) {
              Logger.info(
                  '[WalletViewsLiveUpdater]   [${i}] Raw Amount: ${prevAsset.rawAmount} → ${currentAsset.rawAmount}');
            }
          }
        }
      }
    }
  }
}

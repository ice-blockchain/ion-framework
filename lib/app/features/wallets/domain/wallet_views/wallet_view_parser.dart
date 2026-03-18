// SPDX-License-Identifier: ice License 1.0

part of 'wallet_views_service.r.dart';

@riverpod
WalletViewParser walletViewParser(Ref ref) {
  return WalletViewParser(ref.watch(coinsRepositoryProvider));
}

class WalletViewParser {
  const WalletViewParser(this.coinsRepository);

  final CoinsRepository coinsRepository;

  Future<WalletViewData> parse(
    WalletView viewDTO,
    Map<String, NetworkData> networks, {
    required bool isMainWalletView,
  }) async {
    final coinGroups = <String, CoinsGroup>{};
    final symbolGroups = <String>{};
    var totalViewBalanceUSD = 0.0;

    final consumedAggregationWallets = <String>{};

    for (final coinInWalletDTO in viewDTO.coins) {
      final coinInWallet = await _processCoinInWallet(
        coinInWalletDTO,
        networks,
        viewDTO.aggregation,
        consumedAggregationWallets,
      );

      if (coinInWallet == null) continue;

      totalViewBalanceUSD += coinInWallet.balanceUSD;
      final symbolGroup = coinInWallet.coin.symbolGroup;
      symbolGroups.add(symbolGroup);

      coinGroups[symbolGroup] = _updateCoinGroup(coinInWallet, symbolGroup, coinGroups);
    }

    return WalletViewData(
      coinGroups: coinGroups.values.sorted(CoinsComparator().compareGroups),
      id: viewDTO.id,
      name: viewDTO.name,
      symbolGroups: symbolGroups,
      nfts: viewDTO.nfts?.map((nft) => nft.toNft(networks[nft.network]!)).toList() ?? [],
      createdAt: viewDTO.createdAt.microsecondsSinceEpoch,
      updatedAt: viewDTO.updatedAt.microsecondsSinceEpoch,
      usdBalance: totalViewBalanceUSD,
      isMainWalletView: isMainWalletView,
    );
  }

  Future<CoinInWalletData?> _processCoinInWallet(
    CoinInWallet coinInWalletDTO,
    Map<String, NetworkData> networks,
    Map<String, WalletViewAggregationItem> aggregation,
    Set<String> consumedAggregationWallets,
  ) async {
    final coinDTO = coinInWalletDTO.coin;
    final network = networks[coinDTO.network];

    if (network == null) {
      Logger.error(
        'Network not found for coin ${coinDTO.name}(${coinDTO.id}) in ${coinDTO.network}',
      );
      return null;
    }

    final coin = await _getValidCoinData(coinDTO, network);
    if (coin == null) {
      Logger.error('Coin not found for coin ${coinDTO.name}(${coinDTO.id})');
      return null;
    }

    final aggregationItem =
        _searchAggregationItem(coinInWalletDTO: coinInWalletDTO, aggregation: aggregation);
    final matchedWallet = aggregationItem?.wallets.firstWhereOrNull(
      (wallet) => _isMatchingWallet(wallet, coinInWalletDTO),
    );

    WalletAsset? walletAsset;
    if (matchedWallet != null) {
      final key = _aggregationWalletKey(matchedWallet);
      if (!consumedAggregationWallets.contains(key)) {
        consumedAggregationWallets.add(key);
        walletAsset = matchedWallet.asset;
      }
    }

    final amounts = _calculateCoinAmounts(coinInWalletDTO, walletAsset, coinDTO);
    final walletAssetContractAddress = walletAsset?.maybeMap(
      erc20: (value) => value.contract,
      trc20: (value) => value.contract,
      unknown: (value) => value.contract,
      orElse: () => null,
    );

    final walletAssetAddressToSave =
        walletAssetContractAddress != coin.contractAddress ? walletAssetContractAddress : null;

    return CoinInWalletData(
      coin: coin,
      amount: amounts.coinAmount,
      rawAmount: amounts.rawCoinAmount,
      balanceUSD: amounts.coinBalanceUSD,
      walletId: coinInWalletDTO.walletId,
      walletAssetContractAddress: walletAssetAddressToSave,
    );
  }

  Future<CoinData?> _getValidCoinData(Coin coinDTO, NetworkData network) async {
    var coin = CoinData.fromDTO(coinDTO, network);
    if (!coin.isValid) {
      final fromDB = await coinsRepository.getCoinById(coinDTO.id);
      if (fromDB != null) coin = fromDB;
    }

    // Coin still is not valid, even after adding info from the DB.
    // Log it and return null.
    if (!coin.isValid) {
      Logger.info(
        'Invalid coin filtered out: ${coinDTO.id} '
        '(name: "${coinDTO.name}", symbol: "${coinDTO.symbol}", '
        'network: ${network.id}, contractAddress: "${coinDTO.contractAddress}")',
      );
      return null;
    }

    return coin;
  }

  ({double coinAmount, String rawCoinAmount, double coinBalanceUSD}) _calculateCoinAmounts(
    CoinInWallet coinInWalletDTO,
    WalletAsset? asset,
    Coin coinDTO,
  ) {
    var coinAmount = 0.0;
    var rawCoinAmount = '0';
    var coinBalanceUSD = 0.0;

    if (asset != null) {
      rawCoinAmount = asset.balance;
      coinAmount = fromBlockchainUnits(asset.balance, decimals: asset.decimals);
      coinBalanceUSD = coinAmount * coinDTO.priceUSD;
    }

    return (
      coinAmount: coinAmount,
      rawCoinAmount: rawCoinAmount,
      coinBalanceUSD: coinBalanceUSD,
    );
  }

  CoinsGroup _updateCoinGroup(
    CoinInWalletData coinInWallet,
    String symbolGroup,
    Map<String, CoinsGroup> coinGroups,
  ) {
    final currentGroup = coinGroups[symbolGroup] ?? CoinsGroup.fromCoin(coinInWallet.coin);
    return currentGroup.copyWith(
      totalAmount: currentGroup.totalAmount + coinInWallet.amount,
      totalBalanceUSD: currentGroup.totalBalanceUSD + coinInWallet.balanceUSD,
      coins: [
        ...currentGroup.coins,
        coinInWallet,
      ],
    );
  }

  bool _isMatchingWallet(
    WalletViewAggregationWallet wallet,
    CoinInWallet coinInWalletDTO,
  ) {
    if (wallet.walletId != coinInWalletDTO.walletId) return false;

    final assetContract = _extractContractAddress(wallet.asset);
    final coinContract = coinInWalletDTO.coin.contractAddress;
    if (assetContract != null &&
        assetContract.isNotEmpty &&
        coinContract.isNotEmpty &&
        assetContract.toLowerCase() == coinContract.toLowerCase()) {
      return true;
    }

    return wallet.coinId == null || wallet.coinId == coinInWalletDTO.coin.id;
  }

  String _aggregationWalletKey(WalletViewAggregationWallet wallet) {
    final contract = _extractContractAddress(wallet.asset);
    return '${wallet.walletId}|${wallet.network}|${contract ?? wallet.coinId}';
  }

  String? _extractContractAddress(WalletAsset asset) {
    return asset.maybeMap(
      erc20: (value) => value.contract,
      trc20: (value) => value.contract,
      native: (value) => value.contract,
      unknown: (value) => value.contract,
      orElse: () => null,
    );
  }

  WalletViewAggregationItem? _searchAggregationItem({
    required CoinInWallet coinInWalletDTO,
    required Map<String, WalletViewAggregationItem> aggregation,
  }) {
    WalletViewAggregationItem? search(Iterable<WalletViewAggregationItem> aggregationItems) {
      for (final aggregationItem in aggregationItems) {
        final associatedWallet = aggregationItem.wallets.firstWhereOrNull(
          (e) => _isMatchingWallet(e, coinInWalletDTO),
        );
        if (associatedWallet != null && associatedWallet.network == coinInWalletDTO.coin.network) {
          return aggregationItem;
        }
      }
      return null;
    }

    // Return aggregation item if aggregation map contains coin symbol as a key
    // with the same wallet and coin ids as in CoinInWallet
    final symbol = coinInWalletDTO.coin.symbol.toLowerCase();

    if (aggregation[symbol] case final WalletViewAggregationItem aggregationItem) {
      final result = search([aggregationItem]);
      if (result != null) return result;
    }

    // Attempt to find an aggregation item by indirect signs.
    // The search is performed on all aggregation items with a check
    // for matching the wallet ID, network, and coinId.
    return search(aggregation.values);
  }
}

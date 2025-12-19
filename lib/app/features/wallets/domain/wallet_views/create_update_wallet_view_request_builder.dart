// SPDX-License-Identifier: ice License 1.0

part of 'wallet_views_service.r.dart';

typedef _RequestParams = (Set<String>, List<WalletViewCoinData>);

class _CreateUpdateRequestBuilder {
  CreateUpdateWalletViewRequest build({
    String? name,
    WalletViewData? walletView,
    List<CoinData>? coinsList,
    List<Wallet>? userWallets,
    Wallet? mainUserWallet,
  }) {
    if (name == null && walletView == null) {
      throw UpdateWalletViewRequestWithoutDataException();
    }

    if (coinsList != null && (userWallets == null || mainUserWallet == null)) {
      throw UpdateWalletViewRequestNoUserWalletsException();
    }

    final (symbolGroups, items) = switch (coinsList) {
      final List<CoinData> coins => _getRequestDataFromCoinsList(
          coins,
          mainUserWallet!,
          userWallets!,
          walletView,
        ),
      null when walletView != null => _getRequestDataFromWalletView(walletView),
      _ => (const <String>{}, const <WalletViewCoinData>[]),
    };

    return CreateUpdateWalletViewRequest(
      items: items,
      symbolGroups: symbolGroups.toList(),
      name: name ?? walletView!.name,
    );
  }

  _RequestParams _getRequestDataFromWalletView(
    WalletViewData walletView,
  ) {
    final symbolGroups = <String>{};
    final walletViewItems = <WalletViewCoinData>[];

    for (final coinsGroup in walletView.coinGroups) {
      for (final coinInWallet in coinsGroup.coins) {
        final coin = coinInWallet.coin;
        symbolGroups.add(coin.symbolGroup);
        walletViewItems.add(
          WalletViewCoinData(
            coinId: coin.id,
            walletId: coinInWallet.walletId,
          ),
        );
      }
    }

    return (symbolGroups, walletViewItems);
  }

  _RequestParams _getRequestDataFromCoinsList(
    List<CoinData> coins,
    Wallet mainUserWallet,
    List<Wallet> userWallets,
    WalletViewData? walletView,
  ) {
    final symbolGroups = <String>{};
    final walletViewItems = <WalletViewCoinData>[];

    final networkWithWallet = <String, List<Wallet>>{};
    for (final wallet in userWallets) {
      final network = wallet.network;
      networkWithWallet.putIfAbsent(network, () => []).add(wallet);
    }

    for (final coin in coins) {
      final walletViewId = walletView?.id;
      final coinNetworkId = coin.network.id;
      final walletsInNetwork = networkWithWallet[coinNetworkId];
      final isMainWalletView = walletView?.isMainWalletView ?? false;

      final walletId = _resolveWalletIdForCoin(
        mainUserWallet: mainUserWallet,
        coinNetworkId: coinNetworkId,
        walletsInNetwork: walletsInNetwork,
        walletViewId: walletViewId,
        isMainWalletView: isMainWalletView,
      );

      symbolGroups.add(coin.symbolGroup);
      walletViewItems.add(
        WalletViewCoinData(
          coinId: coin.id,
          walletId: walletId,
        ),
      );
    }

    return (symbolGroups, walletViewItems);
  }

  String? _resolveWalletIdForCoin({
    required Wallet mainUserWallet,
    required String coinNetworkId,
    required List<Wallet>? walletsInNetwork,
    required String? walletViewId,
    required bool isMainWalletView,
  }) {
    // No wallets found for this network: only safe fallback is main wallet if it matches the network.
    if (walletsInNetwork == null || walletsInNetwork.isEmpty) {
      return mainUserWallet.network == coinNetworkId ? mainUserWallet.id : null;
    }

    final matched = walletsInNetwork.firstWhereOrNull((wallet) {
      if (isMainWalletView) {
        final isAutoCreatedMainWallet =
            wallet.name != null && wallet.name!.toLowerCase().contains('main');

        return wallet.id == mainUserWallet.id ||
            wallet.name == walletViewId ||
            isAutoCreatedMainWallet;
      }
      return wallet.name == walletViewId;
    });

    return matched?.id;
  }
}

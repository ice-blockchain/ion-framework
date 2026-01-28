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

    // Build existing bindings from wallet view
    final existingBindings = <String, String?>{};
    if (walletView != null) {
      for (final group in walletView.coinGroups) {
        for (final coinInWallet in group.coins) {
          existingBindings[coinInWallet.coin.id] = coinInWallet.walletId;
        }
      }
    }

    // Get wallets connected to this wallet view, grouped by network
    final networkWithWallets = _getConnectedWalletsByNetwork(
      userWallets: userWallets,
      mainUserWallet: mainUserWallet,
      walletView: walletView,
    );

    // Process each coin
    for (final coin in coins) {
      symbolGroups.add(coin.symbolGroup);

      // Reuse existing binding, or resolve wallet for new coins
      final walletId = existingBindings.containsKey(coin.id)
          ? existingBindings[coin.id]
          : networkWithWallets[coin.network.id]?.firstOrNull?.id;

      walletViewItems.add(
        WalletViewCoinData(
          coinId: coin.id,
          walletId: walletId,
        ),
      );
    }

    return (symbolGroups, walletViewItems);
  }

  Map<String, List<Wallet>> _getConnectedWalletsByNetwork({
    required List<Wallet> userWallets,
    required Wallet mainUserWallet,
    required WalletViewData? walletView,
  }) {
    final connectedWalletIds =
        walletView?.coins.map((c) => c.walletId).nonNulls.toSet() ?? <String>{};

    final walletViewId = walletView?.id;
    final isMainWalletView = walletView?.isMainWalletView ?? false;

    final connectedWallets = userWallets.where((wallet) {
      if (connectedWalletIds.contains(wallet.id)) return true;

      if (isMainWalletView) {
        final isAutoCreatedMainWallet =
            wallet.name != null && wallet.name!.toLowerCase().contains('main');
        return wallet.id == mainUserWallet.id ||
            wallet.name == walletViewId ||
            isAutoCreatedMainWallet;
      }
      return wallet.name == walletViewId;
    }).toList();

    final networkWithWallets = <String, List<Wallet>>{};
    for (final wallet in connectedWallets) {
      networkWithWallets.putIfAbsent(wallet.network, () => []).add(wallet);
    }

    return networkWithWallets;
  }
}

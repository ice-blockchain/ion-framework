// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/data/repository/swap_okx_repository.r.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/swap_coin_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/swap_coins_modal_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_coins_controller_provider.r.g.dart';

@Riverpod(keepAlive: true)
class SwapCoinsController extends _$SwapCoinsController {
  @override
  SwapCoinData build() => const SwapCoinData();

  void initSellCoin({
    required CoinsGroup? coin,
    required NetworkData? network,
  }) =>
      state = state.copyWith(
        sellCoin: coin,
        sellNetwork: network,
        buyCoin: null,
        buyNetwork: null,
      );

  void setSellCoin(CoinsGroup coin) => state = state.copyWith(
        sellCoin: coin,
      );

  void setSellNetwork(NetworkData network) => state = state.copyWith(
        sellNetwork: network,
      );

  void setBuyCoin(CoinsGroup coin) => state = state.copyWith(
        buyCoin: coin,
      );

  void setBuyNetwork(NetworkData network) => state = state.copyWith(
        buyNetwork: network,
      );

  void switchCoins() {
    final sellCoin = state.sellCoin;
    final buyCoin = state.buyCoin;
    final sellNetwork = state.sellNetwork;
    final buyNetwork = state.buyNetwork;

    state = state.copyWith(
      sellCoin: buyCoin,
      buyCoin: sellCoin,
      sellNetwork: buyNetwork,
      buyNetwork: sellNetwork,
    );
  }

  Future<({CoinsGroup? coin, NetworkData? network})> selectCoin({
    required CoinSwapType type,
    required CoinsGroup coin,
    required Future<NetworkData?> Function() selectNetworkRouteLocationBuilder,
  }) async {
    switch (type) {
      case CoinSwapType.sell:
        setSellCoin(coin);
      case CoinSwapType.buy:
        setBuyCoin(coin);
    }

    final result = await selectNetworkRouteLocationBuilder();
    if (result != null) {
      switch (type) {
        case CoinSwapType.sell:
          setSellNetwork(result);
        case CoinSwapType.buy:
          setBuyNetwork(result);
      }
    }

    return (
      coin: state.sellCoin,
      network: state.sellNetwork,
    );
  }

  // TODO(ice-erebus): implement bridge and CEX
  Future<void> swapCoins() async {
    final sellNetwork = state.sellNetwork;
    final buyNetwork = state.buyNetwork;

    if (sellNetwork?.id == buyNetwork?.id) {
      final isChainSupported = await _isChainSupported();

      if (isChainSupported) {}
    }

    return;
  }

  Future<bool> _isChainSupported() async {
    final swapOkxRepository = await ref.read(swapOkxRepositoryProvider.future);
    await swapOkxRepository.getSupportedChains();

    return true;
  }
}

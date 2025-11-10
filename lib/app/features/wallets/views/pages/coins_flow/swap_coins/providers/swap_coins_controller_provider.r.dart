// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/swap_coin_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/services/ion_swap_client/ion_swap_client_provider.r.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
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

  Future<void> swapCoins({
    required String userSellAddress,
    required String userBuyAddress,
  }) async {
    final sellNetwork = state.sellNetwork;
    final buyNetwork = state.buyNetwork;
    final sellCoinGroup = state.sellCoin;
    final buyCoinGroup = state.buyCoin;

    if (sellCoinGroup == null || buyCoinGroup == null || sellNetwork == null || buyNetwork == null) {
      return;
    }

    final sellCoin = sellCoinGroup.coins.firstWhereOrNull((coin) => coin.coin.network.id == sellNetwork.id);
    final buyCoin = buyCoinGroup.coins.firstWhereOrNull((coin) => coin.coin.network.id == buyNetwork.id);

    if (sellCoin == null || buyCoin == null) {
      return;
    }

    final swapController = await ref.read(ionSwapClientProvider.future);
    await swapController.swapCoins(
      // TODO(ice-erebus): add amount
      swapCoinData: SwapCoinParameters(
        isBridge: buyCoinGroup == sellCoinGroup,
        amount: '1000',
        buyCoinContractAddress: buyCoin.coin.contractAddress,
        sellCoinContractAddress: sellCoin.coin.contractAddress,
        buyCoinNetworkName: buyNetwork.displayName,
        sellCoinNetworkName: sellNetwork.displayName,
        buyNetworkId: buyNetwork.id,
        sellNetworkId: sellNetwork.id,
        userBuyAddress: userBuyAddress,
        userSellAddress: userSellAddress,
      ),
    );
  }
}

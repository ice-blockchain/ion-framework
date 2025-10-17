// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/swap_coin_data.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_coins_controller_provider.r.g.dart';

@Riverpod(keepAlive: true)
class SwapCoinsController extends _$SwapCoinsController {
  @override
  SwapCoinData build() => const SwapCoinData(
        sellCoin: null,
        sellNetwork: null,
        buyCoin: null,
        buyNetwork: null,
      );

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

  void setSellCoin(
    CoinsGroup coin,
  ) =>
      state = state.copyWith(
        sellCoin: coin,
      );

  void setSellNetwork(
    NetworkData network,
  ) =>
      state = state.copyWith(
        sellNetwork: network,
      );

  void setBuyCoin(
    CoinsGroup coin,
  ) =>
      state = state.copyWith(
        buyCoin: coin,
      );

  void setBuyNetwork(
    NetworkData network,
  ) =>
      state = state.copyWith(
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
}

// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/model/coin_balance_state.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/providers/synced_coins_by_symbol_group_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/network_selector_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'balance_provider.r.g.dart';

@riverpod
CoinBalanceState coinBalance(Ref ref, {required String symbolGroup}) {
  final coinsValue = ref.watch(syncedCoinsBySymbolGroupProvider(symbolGroup));
  final coins = coinsValue.valueOrNull ?? <CoinInWalletData>[];

  final currentNetwork = ref.watch(
    networkSelectorNotifierProvider(symbolGroup: symbolGroup).select(
      (state) => state?.selected.whenOrNull(network: (network) => network),
    ),
  );

  final filteredCoins = currentNetwork == null
      ? coins
      : coins.where((CoinInWalletData coin) => coin.coin.network.id == currentNetwork.id).toList();

  final totalAmount = filteredCoins.fold<double>(
    0,
    (double sum, CoinInWalletData coin) => sum + coin.amount,
  );
  final totalBalanceUSD = filteredCoins.fold<double>(
    0,
    (double sum, CoinInWalletData coin) => sum + coin.balanceUSD,
  );

  return CoinBalanceState(amount: totalAmount, balanceUSD: totalBalanceUSD);
}

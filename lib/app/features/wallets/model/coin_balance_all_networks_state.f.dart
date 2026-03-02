// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/coin_balance_state.f.dart';

part 'coin_balance_all_networks_state.f.freezed.dart';

@freezed
class CoinBalanceAllNetworksState with _$CoinBalanceAllNetworksState {
  const factory CoinBalanceAllNetworksState({
    required Map<String, CoinBalanceState> balancesByNetwork,
    required String selectedNetworkKey,
  }) = _CoinBalanceAllNetworksState;

  const CoinBalanceAllNetworksState._();

  static const String allNetworksKey = 'ALL';

  CoinBalanceState get selectedBalance =>
      balancesByNetwork[selectedNetworkKey] ?? const CoinBalanceState();

  CoinBalanceState? getBalance(String networkKey) => balancesByNetwork[networkKey];
}

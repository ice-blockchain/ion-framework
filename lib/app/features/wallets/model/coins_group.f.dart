// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';

part 'coins_group.f.freezed.dart';

@freezed
class CoinsGroup with _$CoinsGroup {
  const factory CoinsGroup({
    required String name,
    required String symbolGroup,
    required String abbreviation,
    required List<CoinInWalletData> coins,
    String? iconUrl,
    @Default(0) double totalAmount,
    @Default(0) double totalBalanceUSD,
  }) = _CoinsGroup;

  factory CoinsGroup.fromCoin(CoinData coin) {
    return CoinsGroup(
      name: coin.name,
      iconUrl: coin.iconUrl,
      symbolGroup: coin.symbolGroup,
      abbreviation: coin.abbreviation,
      coins: [],
    );
  }

  factory CoinsGroup.fromCoinsData(Iterable<CoinData> coins) {
    final coin = coins.first;
    return CoinsGroup(
      name: coin.name,
      iconUrl: coin.iconUrl,
      symbolGroup: coin.symbolGroup,
      abbreviation: coin.abbreviation,
      coins: coins.map((coin) => CoinInWalletData(coin: coin)).toList(),
    );
  }

  const CoinsGroup._();
}

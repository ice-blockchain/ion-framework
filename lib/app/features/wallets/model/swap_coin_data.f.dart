// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';

part 'swap_coin_data.f.freezed.dart';

@freezed
class SwapCoinData with _$SwapCoinData {
  const factory SwapCoinData({
    CoinsGroup? sellCoin,
    NetworkData? sellNetwork,
    CoinsGroup? buyCoin,
    NetworkData? buyNetwork,
    SwapQuoteInfo? swapQuoteInfo,
    @Default(false) bool isQuoteLoading,
  }) = _SwapCoinData;

  const SwapCoinData._();
}

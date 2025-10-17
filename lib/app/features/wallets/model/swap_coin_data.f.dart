// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';

part 'swap_coin_data.f.freezed.dart';

@freezed
class SwapCoinData with _$SwapCoinData {
  const factory SwapCoinData({
    required CoinsGroup? sellCoin,
    required NetworkData? sellNetwork,
    required CoinsGroup? buyCoin,
    required NetworkData? buyNetwork,
  }) = _SwapCoinData;

  const SwapCoinData._();
}

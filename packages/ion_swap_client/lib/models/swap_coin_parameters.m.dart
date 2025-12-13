// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_swap_client/models/swap_coin.m.dart';

part 'swap_coin_parameters.m.freezed.dart';
part 'swap_coin_parameters.m.g.dart';

@freezed
class SwapCoinParameters with _$SwapCoinParameters {
  factory SwapCoinParameters({
    required String? userSellAddress,
    required String? userBuyAddress,
    required String amount,
    required bool isBridge,
    required SwapCoin sellCoin,
    required SwapCoin buyCoin,
    required String slippage,
  }) = _SwapCoinParameters;

  factory SwapCoinParameters.fromJson(Map<String, dynamic> json) =>
      _$SwapCoinParametersFromJson(json);
}

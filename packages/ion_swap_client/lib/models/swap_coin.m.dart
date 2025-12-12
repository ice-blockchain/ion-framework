// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_swap_client/models/swap_network.m.dart';

part 'swap_coin.m.freezed.dart';
part 'swap_coin.m.g.dart';

@freezed
class SwapCoin with _$SwapCoin {
  factory SwapCoin({
    required String contractAddress,
    required String code,
    required int decimal,
    required SwapNetwork network,

    /// Used for lets exchange. It's extra id used for some coins,
    /// fox example for XPR it's memo
    required String extraId,
  }) = _SwapCoin;

  factory SwapCoin.fromJson(Map<String, dynamic> json) => _$SwapCoinFromJson(json);
}

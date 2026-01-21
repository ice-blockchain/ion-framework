// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';

part 'expected_swap_data.f.freezed.dart';

@freezed
class ExpectedSwapData with _$ExpectedSwapData {
  const factory ExpectedSwapData({
    required CoinsGroup coinsGroup,
    required NetworkData network,
    required String amount,
  }) = _ExpectedSwapData;
}

// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';

part 'swap_side_data.f.freezed.dart';

@freezed
class SwapSideData with _$SwapSideData {
  const factory SwapSideData({
    required CoinsGroup coins,
    required NetworkData network,
    required String amount,
  }) = _SwapSideData;
}

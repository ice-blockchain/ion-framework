// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/swap_side_data.f.dart';

part 'swap_display_data.f.freezed.dart';

@freezed
class SwapDisplayData with _$SwapDisplayData {
  const factory SwapDisplayData({
    required SwapSideData sellData,
    required SwapSideData buyData,
    required double exchangeRate,
    required bool hideBuyAmount,
  }) = _SwapDisplayData;
}

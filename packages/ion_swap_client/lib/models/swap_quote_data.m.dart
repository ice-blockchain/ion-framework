// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_swap_client/models/okx_token_info.m.dart';

part 'swap_quote_data.m.freezed.dart';
part 'swap_quote_data.m.g.dart';

@freezed
class SwapQuoteData with _$SwapQuoteData {
  factory SwapQuoteData({
    required String chainIndex,
    required String fromTokenAmount,
    required String toTokenAmount,
    required OkxTokenInfo fromToken,
    required OkxTokenInfo toToken,
  }) = _SwapQuoteData;

  factory SwapQuoteData.fromJson(Map<String, dynamic> json) => _$SwapQuoteDataFromJson(json);
}

extension SwapQuoteDataExtension on SwapQuoteData {
  double get priceForSellTokenInBuyToken {
    final fromAmount = double.parse(fromTokenAmount);
    final fromDecimals = double.parse(fromToken.decimal);
    final toAmountRaw = double.parse(toTokenAmount);
    final toDecimals = double.parse(toToken.decimal);

    final toAmount = toAmountRaw / pow(10, toDecimals - fromDecimals);

    return toAmount / fromAmount;
  }
}

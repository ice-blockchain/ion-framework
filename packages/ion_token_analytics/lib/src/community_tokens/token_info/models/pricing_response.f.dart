// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pricing_response.f.freezed.dart';
part 'pricing_response.f.g.dart';

@freezed
class PricingResponse with _$PricingResponse {
  const factory PricingResponse({
    required String amount,
    required String amountBNB,
    required double amountUSD,
    double? usdPriceION,
    double? usdPriceBNB,
  }) = _PricingResponse;

  factory PricingResponse.fromJson(Map<String, dynamic> json) => _$PricingResponseFromJson(json);
}

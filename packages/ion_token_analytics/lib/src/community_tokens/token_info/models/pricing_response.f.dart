// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pricing_response.f.freezed.dart';
part 'pricing_response.f.g.dart';

@freezed
class CreatorTokenParams with _$CreatorTokenParams {
  const factory CreatorTokenParams({
    String? bondingCurveAlgAddress,
    String? emissionVolume,
    String? finalPrice,
    double? finalPriceUSD,
    String? initialPrice,
    double? initialPriceUSD,
  }) = _CreatorTokenParams;

  factory CreatorTokenParams.fromJson(Map<String, dynamic> json) =>
      _$CreatorTokenParamsFromJson(json);
}

@freezed
class PricingResponse with _$PricingResponse {
  const factory PricingResponse({
    required String feeSponsorId,
    required String amount,
    required String amountBNB,
    required double amountUSD,
    String? bondingCurveAlgAddress,
    CreatorTokenParams? creatorTokenParams,
    String? emissionVolume,
    String? feeSponsorAddress,
    String? feeSponsorId,
    String? finalPrice,
    double? finalPriceUSD,
    String? initialPrice,
    double? initialPriceUSD,
    double? usdPriceION,
    double? usdPriceBNB,
  }) = _PricingResponse;

  factory PricingResponse.fromJson(Map<String, dynamic> json) => _$PricingResponseFromJson(json);
}

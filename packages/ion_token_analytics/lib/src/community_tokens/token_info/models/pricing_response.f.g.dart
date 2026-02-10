// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pricing_response.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CreatorTokenParamsImpl _$$CreatorTokenParamsImplFromJson(
  Map<String, dynamic> json,
) => _$CreatorTokenParamsImpl(
  bondingCurveAlgAddress: json['bondingCurveAlgAddress'] as String?,
  emissionVolume: json['emissionVolume'] as String?,
  finalPrice: json['finalPrice'] as String?,
  finalPriceUSD: (json['finalPriceUSD'] as num?)?.toDouble(),
  initialPrice: json['initialPrice'] as String?,
  initialPriceUSD: (json['initialPriceUSD'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$CreatorTokenParamsImplToJson(
  _$CreatorTokenParamsImpl instance,
) => <String, dynamic>{
  if (instance.bondingCurveAlgAddress case final value?)
    'bondingCurveAlgAddress': value,
  if (instance.emissionVolume case final value?) 'emissionVolume': value,
  if (instance.finalPrice case final value?) 'finalPrice': value,
  if (instance.finalPriceUSD case final value?) 'finalPriceUSD': value,
  if (instance.initialPrice case final value?) 'initialPrice': value,
  if (instance.initialPriceUSD case final value?) 'initialPriceUSD': value,
};

_$PricingResponseImpl _$$PricingResponseImplFromJson(
  Map<String, dynamic> json,
) => _$PricingResponseImpl(
  feeSponsorId: json['feeSponsorId'] as String,
  amount: json['amount'] as String,
  amountBNB: json['amountBNB'] as String,
  amountUSD: (json['amountUSD'] as num).toDouble(),
  bondingCurveAlgAddress: json['bondingCurveAlgAddress'] as String?,
  creatorTokenParams: json['creatorTokenParams'] == null
      ? null
      : CreatorTokenParams.fromJson(
          json['creatorTokenParams'] as Map<String, dynamic>,
        ),
  emissionVolume: json['emissionVolume'] as String?,
  feeSponsorAddress: json['feeSponsorAddress'] as String?,
  feeSponsorId: json['feeSponsorId'] as String,
  finalPrice: json['finalPrice'] as String?,
  finalPriceUSD: (json['finalPriceUSD'] as num?)?.toDouble(),
  initialPrice: json['initialPrice'] as String?,
  initialPriceUSD: (json['initialPriceUSD'] as num?)?.toDouble(),
  usdPriceION: (json['usdPriceION'] as num?)?.toDouble(),
  usdPriceBNB: (json['usdPriceBNB'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$PricingResponseImplToJson(
  _$PricingResponseImpl instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'amountBNB': instance.amountBNB,
  'amountUSD': instance.amountUSD,
  if (instance.bondingCurveAlgAddress case final value?)
    'bondingCurveAlgAddress': value,
  if (instance.creatorTokenParams?.toJson() case final value?)
    'creatorTokenParams': value,
  if (instance.emissionVolume case final value?) 'emissionVolume': value,
  if (instance.feeSponsorAddress case final value?) 'feeSponsorAddress': value,
  if (instance.feeSponsorId case final value?) 'feeSponsorId': value,
  if (instance.finalPrice case final value?) 'finalPrice': value,
  if (instance.finalPriceUSD case final value?) 'finalPriceUSD': value,
  if (instance.initialPrice case final value?) 'initialPrice': value,
  if (instance.initialPriceUSD case final value?) 'initialPriceUSD': value,
  if (instance.usdPriceION case final value?) 'usdPriceION': value,
  if (instance.usdPriceBNB case final value?) 'usdPriceBNB': value,
};

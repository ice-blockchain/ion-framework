// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pricing_response.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PricingResponseImpl _$$PricingResponseImplFromJson(
  Map<String, dynamic> json,
) => _$PricingResponseImpl(
  amount: json['amount'] as String,
  amountBNB: json['amountBNB'] as String,
  amountUSD: (json['amountUSD'] as num).toDouble(),
  usdPriceION: (json['usdPriceION'] as num?)?.toDouble(),
  usdPriceBNB: (json['usdPriceBNB'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$PricingResponseImplToJson(
  _$PricingResponseImpl instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'amountBNB': instance.amountBNB,
  'amountUSD': instance.amountUSD,
  if (instance.usdPriceION case final value?) 'usdPriceION': value,
  if (instance.usdPriceBNB case final value?) 'usdPriceBNB': value,
};

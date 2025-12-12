// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swap_quote_data.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SwapQuoteDataImpl _$$SwapQuoteDataImplFromJson(Map<String, dynamic> json) =>
    _$SwapQuoteDataImpl(
      chainIndex: json['chainIndex'] as String,
      fromTokenAmount: json['fromTokenAmount'] as String,
      toTokenAmount: json['toTokenAmount'] as String,
      fromToken:
          OkxTokenInfo.fromJson(json['fromToken'] as Map<String, dynamic>),
      toToken: OkxTokenInfo.fromJson(json['toToken'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$SwapQuoteDataImplToJson(_$SwapQuoteDataImpl instance) =>
    <String, dynamic>{
      'chainIndex': instance.chainIndex,
      'fromTokenAmount': instance.fromTokenAmount,
      'toTokenAmount': instance.toTokenAmount,
      'fromToken': instance.fromToken,
      'toToken': instance.toToken,
    };

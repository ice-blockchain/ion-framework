// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_quote_details.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RelayQuoteDetailsImpl _$$RelayQuoteDetailsImplFromJson(
        Map<String, dynamic> json) =>
    _$RelayQuoteDetailsImpl(
      rate: json['rate'] as String,
      swapImpact: json['swapImpact'] == null
          ? null
          : RelaySwapImpact.fromJson(
              json['swapImpact'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$RelayQuoteDetailsImplToJson(
        _$RelayQuoteDetailsImpl instance) =>
    <String, dynamic>{
      'rate': instance.rate,
      'swapImpact': instance.swapImpact,
    };

_$RelaySwapImpactImpl _$$RelaySwapImpactImplFromJson(
        Map<String, dynamic> json) =>
    _$RelaySwapImpactImpl(
      percent: json['percent'] as String?,
    );

Map<String, dynamic> _$$RelaySwapImpactImplToJson(
        _$RelaySwapImpactImpl instance) =>
    <String, dynamic>{
      'percent': instance.percent,
    };

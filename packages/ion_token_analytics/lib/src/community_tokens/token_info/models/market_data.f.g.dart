// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_data.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MarketDataImpl _$$MarketDataImplFromJson(Map<String, dynamic> json) =>
    _$MarketDataImpl(
      marketCap: (json['marketCap'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      holders: (json['holders'] as num).toInt(),
      priceUSD: (json['priceUSD'] as num).toDouble(),
      position: json['position'] == null
          ? null
          : Position.fromJson(json['position'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MarketDataImplToJson(_$MarketDataImpl instance) =>
    <String, dynamic>{
      'marketCap': instance.marketCap,
      'volume': instance.volume,
      'holders': instance.holders,
      'priceUSD': instance.priceUSD,
      if (instance.position?.toJson() case final value?) 'position': value,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trading_stats.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TradingStatsImpl _$$TradingStatsImplFromJson(Map<String, dynamic> json) => _$TradingStatsImpl(
  volumeUSD: (json['volumeUSD'] as num).toDouble(),
  numberOfBuys: (json['numberOfBuys'] as num).toInt(),
  buysTotalAmountUSD: (json['buysTotalAmountUSD'] as num).toDouble(),
  numberOfSells: (json['numberOfSells'] as num).toInt(),
  sellsTotalAmountUSD: (json['sellsTotalAmountUSD'] as num).toDouble(),
  netBuy: (json['netBuy'] as num).toDouble(),
);

Map<String, dynamic> _$$TradingStatsImplToJson(_$TradingStatsImpl instance) => <String, dynamic>{
  'volumeUSD': instance.volumeUSD,
  'numberOfBuys': instance.numberOfBuys,
  'buysTotalAmountUSD': instance.buysTotalAmountUSD,
  'numberOfSells': instance.numberOfSells,
  'sellsTotalAmountUSD': instance.sellsTotalAmountUSD,
  'netBuy': instance.netBuy,
};

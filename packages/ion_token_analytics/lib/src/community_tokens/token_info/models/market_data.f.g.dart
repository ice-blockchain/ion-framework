// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_data.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MarketDataImpl _$$MarketDataImplFromJson(Map<String, dynamic> json) =>
    _$MarketDataImpl(
      ticker: json['ticker'] as String,
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
      'ticker': instance.ticker,
      'marketCap': instance.marketCap,
      'volume': instance.volume,
      'holders': instance.holders,
      'priceUSD': instance.priceUSD,
      if (instance.position?.toJson() case final value?) 'position': value,
    };

_$MarketDataPatchImpl _$$MarketDataPatchImplFromJson(
  Map<String, dynamic> json,
) => _$MarketDataPatchImpl(
  ticker: json['ticker'] as String?,
  marketCap: (json['marketCap'] as num?)?.toDouble(),
  volume: (json['volume'] as num?)?.toDouble(),
  holders: (json['holders'] as num?)?.toInt(),
  priceUSD: (json['priceUSD'] as num?)?.toDouble(),
  position: json['position'] == null
      ? null
      : PositionPatch.fromJson(json['position'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$MarketDataPatchImplToJson(
  _$MarketDataPatchImpl instance,
) => <String, dynamic>{
  if (instance.ticker case final value?) 'ticker': value,
  if (instance.marketCap case final value?) 'marketCap': value,
  if (instance.volume case final value?) 'volume': value,
  if (instance.holders case final value?) 'holders': value,
  if (instance.priceUSD case final value?) 'priceUSD': value,
  if (instance.position?.toJson() case final value?) 'position': value,
};

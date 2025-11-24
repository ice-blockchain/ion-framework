// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_data_patch.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MarketDataPatchImpl _$$MarketDataPatchImplFromJson(
  Map<String, dynamic> json,
) => _$MarketDataPatchImpl(
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
  if (instance.marketCap case final value?) 'marketCap': value,
  if (instance.volume case final value?) 'volume': value,
  if (instance.holders case final value?) 'holders': value,
  if (instance.priceUSD case final value?) 'priceUSD': value,
  if (instance.position?.toJson() case final value?) 'position': value,
};

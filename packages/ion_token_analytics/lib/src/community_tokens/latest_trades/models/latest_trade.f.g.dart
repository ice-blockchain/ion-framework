// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'latest_trade.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LatestTradeImpl _$$LatestTradeImplFromJson(Map<String, dynamic> json) =>
    _$LatestTradeImpl(
      creator: Creator.fromJson(json['creator'] as Map<String, dynamic>),
      position: TradePosition.fromJson(
        json['position'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$$LatestTradeImplToJson(_$LatestTradeImpl instance) =>
    <String, dynamic>{
      'creator': instance.creator.toJson(),
      'position': instance.position.toJson(),
    };

_$LatestTradePatchImpl _$$LatestTradePatchImplFromJson(
  Map<String, dynamic> json,
) => _$LatestTradePatchImpl(
  creator: json['creator'] == null
      ? null
      : Creator.fromJson(json['creator'] as Map<String, dynamic>),
  position: json['position'] == null
      ? null
      : TradePositionPatch.fromJson(json['position'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$LatestTradePatchImplToJson(
  _$LatestTradePatchImpl instance,
) => <String, dynamic>{
  if (instance.creator?.toJson() case final value?) 'creator': value,
  if (instance.position?.toJson() case final value?) 'position': value,
};

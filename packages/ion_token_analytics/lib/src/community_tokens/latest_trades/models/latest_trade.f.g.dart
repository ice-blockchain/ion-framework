// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'latest_trade.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LatestTradeImpl _$$LatestTradeImplFromJson(Map<String, dynamic> json) =>
    _$LatestTradeImpl(
      trader: Creator.fromJson(json['trader'] as Map<String, dynamic>),
      amount: (json['amount'] as num).toDouble(),
      amountUSD: (json['amountUSD'] as num).toDouble(),
      timestamp: (json['timestamp'] as num).toInt(),
      side: json['side'] as String,
      addresses: Addresses.fromJson(json['addresses'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$LatestTradeImplToJson(_$LatestTradeImpl instance) =>
    <String, dynamic>{
      'trader': instance.trader.toJson(),
      'amount': instance.amount,
      'amountUSD': instance.amountUSD,
      'timestamp': instance.timestamp,
      'side': instance.side,
      'addresses': instance.addresses.toJson(),
    };

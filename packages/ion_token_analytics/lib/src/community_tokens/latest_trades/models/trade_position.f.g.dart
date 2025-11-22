// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_position.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TradePositionImpl _$$TradePositionImplFromJson(Map<String, dynamic> json) =>
    _$TradePositionImpl(
      holder: Creator.fromJson(json['holder'] as Map<String, dynamic>),
      addresses: Addresses.fromJson(json['addresses'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      amountUSD: (json['amountUSD'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      balanceUSD: (json['balanceUSD'] as num).toDouble(),
    );

Map<String, dynamic> _$$TradePositionImplToJson(_$TradePositionImpl instance) =>
    <String, dynamic>{
      'holder': instance.holder.toJson(),
      'addresses': instance.addresses.toJson(),
      'createdAt': instance.createdAt,
      'type': instance.type,
      'amount': instance.amount,
      'amountUSD': instance.amountUSD,
      'balance': instance.balance,
      'balanceUSD': instance.balanceUSD,
    };

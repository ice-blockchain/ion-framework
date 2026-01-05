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
      type: $enumDecode(_$TradeTypeEnumMap, json['type']),
      amount: json['amount'] as String,
      amountUSD: (json['amountUSD'] as num).toDouble(),
      balance: json['balance'] as String,
      balanceUSD: (json['balanceUSD'] as num).toDouble(),
    );

Map<String, dynamic> _$$TradePositionImplToJson(_$TradePositionImpl instance) =>
    <String, dynamic>{
      'holder': instance.holder.toJson(),
      'addresses': instance.addresses.toJson(),
      'createdAt': instance.createdAt,
      'type': _$TradeTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'amountUSD': instance.amountUSD,
      'balance': instance.balance,
      'balanceUSD': instance.balanceUSD,
    };

const _$TradeTypeEnumMap = {TradeType.buy: 'buy', TradeType.sell: 'sell'};

_$TradePositionPatchImpl _$$TradePositionPatchImplFromJson(
  Map<String, dynamic> json,
) => _$TradePositionPatchImpl(
  holder: json['holder'] == null
      ? null
      : Creator.fromJson(json['holder'] as Map<String, dynamic>),
  addresses: json['addresses'] == null
      ? null
      : AddressesPatch.fromJson(json['addresses'] as Map<String, dynamic>),
  createdAt: json['createdAt'] as String?,
  type: $enumDecodeNullable(_$TradeTypeEnumMap, json['type']),
  amount: json['amount'] as String?,
  amountUSD: (json['amountUSD'] as num?)?.toDouble(),
  balance: json['balance'] as String?,
  balanceUSD: (json['balanceUSD'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$TradePositionPatchImplToJson(
  _$TradePositionPatchImpl instance,
) => <String, dynamic>{
  if (instance.holder?.toJson() case final value?) 'holder': value,
  if (instance.addresses?.toJson() case final value?) 'addresses': value,
  if (instance.createdAt case final value?) 'createdAt': value,
  if (_$TradeTypeEnumMap[instance.type] case final value?) 'type': value,
  if (instance.amount case final value?) 'amount': value,
  if (instance.amountUSD case final value?) 'amountUSD': value,
  if (instance.balance case final value?) 'balance': value,
  if (instance.balanceUSD case final value?) 'balanceUSD': value,
};

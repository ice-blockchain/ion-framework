// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_currency.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RelayCurrencyImpl _$$RelayCurrencyImplFromJson(Map<String, dynamic> json) =>
    _$RelayCurrencyImpl(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      decimals: (json['decimals'] as num).toInt(),
    );

Map<String, dynamic> _$$RelayCurrencyImplToJson(_$RelayCurrencyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'symbol': instance.symbol,
      'name': instance.name,
      'address': instance.address,
      'decimals': instance.decimals,
    };

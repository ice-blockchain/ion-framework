// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lets_exchange_coin.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LetsExchangeCoinImpl _$$LetsExchangeCoinImplFromJson(Map<String, dynamic> json) =>
    _$LetsExchangeCoinImpl(
      code: json['code'] as String,
      name: json['name'] as String,
      isActive: (json['is_active'] as num).toInt(),
      networks: (json['networks'] as List<dynamic>)
          .map((e) => LetsExchangeNetwork.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$LetsExchangeCoinImplToJson(_$LetsExchangeCoinImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'is_active': instance.isActive,
      'networks': instance.networks,
    };

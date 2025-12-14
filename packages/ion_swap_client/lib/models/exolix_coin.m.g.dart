// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exolix_coin.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExolixCoinImpl _$$ExolixCoinImplFromJson(Map<String, dynamic> json) =>
    _$ExolixCoinImpl(
      code: json['code'] as String,
      name: json['name'] as String,
      networks: (json['networks'] as List<dynamic>)
          .map((e) => ExolixNetwork.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ExolixCoinImplToJson(_$ExolixCoinImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'networks': instance.networks,
    };

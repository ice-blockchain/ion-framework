// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chain_data.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChainDataImpl _$$ChainDataImplFromJson(Map<String, dynamic> json) =>
    _$ChainDataImpl(
      name: json['name'] as String,
      networkId: (json['networkId'] as num).toInt(),
    );

Map<String, dynamic> _$$ChainDataImplToJson(_$ChainDataImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'networkId': instance.networkId,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lets_exchange_network.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LetsExchangeNetworkImpl _$$LetsExchangeNetworkImplFromJson(Map<String, dynamic> json) =>
    _$LetsExchangeNetworkImpl(
      code: json['code'] as String,
      name: json['name'] as String,
      isActive: (json['is_active'] as num).toInt(),
      contractAddress: json['contract_address'] as String?,
    );

Map<String, dynamic> _$$LetsExchangeNetworkImplToJson(_$LetsExchangeNetworkImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'is_active': instance.isActive,
      'contract_address': instance.contractAddress,
    };

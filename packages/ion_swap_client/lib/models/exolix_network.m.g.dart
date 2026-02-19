// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exolix_network.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExolixNetworkImpl _$$ExolixNetworkImplFromJson(Map<String, dynamic> json) =>
    _$ExolixNetworkImpl(
      network: json['network'] as String,
      name: json['name'] as String,
      isDefault: json['isDefault'] as bool,
      contract: json['contract'] as String?,
      shortName: json['shortName'] as String? ?? '',
    );

Map<String, dynamic> _$$ExolixNetworkImplToJson(_$ExolixNetworkImpl instance) =>
    <String, dynamic>{
      'network': instance.network,
      'name': instance.name,
      'isDefault': instance.isDefault,
      'contract': instance.contract,
      'shortName': instance.shortName,
    };

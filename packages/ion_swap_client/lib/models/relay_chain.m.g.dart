// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_chain.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RelayChainImpl _$$RelayChainImplFromJson(Map<String, dynamic> json) =>
    _$RelayChainImpl(
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      id: (json['id'] as num).toInt(),
      disabled: json['disabled'] as bool,
      currency:
          RelayCurrency.fromJson(json['currency'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$RelayChainImplToJson(_$RelayChainImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'displayName': instance.displayName,
      'id': instance.id,
      'disabled': instance.disabled,
      'currency': instance.currency,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_step.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RelayStepImpl _$$RelayStepImplFromJson(Map<String, dynamic> json) =>
    _$RelayStepImpl(
      id: json['id'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => RelayStepItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$RelayStepImplToJson(_$RelayStepImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'items': instance.items,
    };

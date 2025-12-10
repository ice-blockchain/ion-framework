// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exolix_error.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExolixErrorImpl _$$ExolixErrorImplFromJson(Map<String, dynamic> json) =>
    _$ExolixErrorImpl(
      fromAmount: json['fromAmount'] as num,
      toAmount: json['toAmount'] as num,
      message: json['message'] as String,
      minAmount: json['minAmount'] as num,
    );

Map<String, dynamic> _$$ExolixErrorImplToJson(_$ExolixErrorImpl instance) =>
    <String, dynamic>{
      'fromAmount': instance.fromAmount,
      'toAmount': instance.toAmount,
      'message': instance.message,
      'minAmount': instance.minAmount,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exolix_rate.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExolixRateImpl _$$ExolixRateImplFromJson(Map<String, dynamic> json) => _$ExolixRateImpl(
      fromAmount: json['fromAmount'] as num,
      toAmount: json['toAmount'] as num,
      rate: json['rate'] as num,
      message: json['message'] as String?,
      minAmount: json['minAmount'] as num,
      withdrawMin: json['withdrawMin'] as num,
      maxAmount: json['maxAmount'] as num,
    );

Map<String, dynamic> _$$ExolixRateImplToJson(_$ExolixRateImpl instance) => <String, dynamic>{
      'fromAmount': instance.fromAmount,
      'toAmount': instance.toAmount,
      'rate': instance.rate,
      'message': instance.message,
      'minAmount': instance.minAmount,
      'withdrawMin': instance.withdrawMin,
      'maxAmount': instance.maxAmount,
    };

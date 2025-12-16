// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bsc_fee_data.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BscFeeDataImpl _$$BscFeeDataImplFromJson(Map<String, dynamic> json) =>
    _$BscFeeDataImpl(
      maxFeePerGas: BigInt.parse(json['maxFeePerGas'] as String),
      maxPriorityFeePerGas:
          BigInt.parse(json['maxPriorityFeePerGas'] as String),
    );

Map<String, dynamic> _$$BscFeeDataImplToJson(_$BscFeeDataImpl instance) =>
    <String, dynamic>{
      'maxFeePerGas': instance.maxFeePerGas.toString(),
      'maxPriorityFeePerGas': instance.maxPriorityFeePerGas.toString(),
    };

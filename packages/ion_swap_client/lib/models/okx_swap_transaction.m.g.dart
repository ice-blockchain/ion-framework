// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'okx_swap_transaction.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OkxSwapTransactionImpl _$$OkxSwapTransactionImplFromJson(
        Map<String, dynamic> json) =>
    _$OkxSwapTransactionImpl(
      data: json['data'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      gas: json['gas'] as String,
      gasPrice: json['gasPrice'] as String,
      value: json['value'] as String,
      maxPriorityFeePerGas: json['maxPriorityFeePerGas'] as String?,
      minReceiveAmount: json['minReceiveAmount'] as String?,
    );

Map<String, dynamic> _$$OkxSwapTransactionImplToJson(
        _$OkxSwapTransactionImpl instance) =>
    <String, dynamic>{
      'data': instance.data,
      'from': instance.from,
      'to': instance.to,
      'gas': instance.gas,
      'gasPrice': instance.gasPrice,
      'value': instance.value,
      'maxPriorityFeePerGas': instance.maxPriorityFeePerGas,
      'minReceiveAmount': instance.minReceiveAmount,
    };

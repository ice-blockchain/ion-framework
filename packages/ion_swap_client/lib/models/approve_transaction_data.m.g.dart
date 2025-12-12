// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approve_transaction_data.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApproveTransactionDataImpl _$$ApproveTransactionDataImplFromJson(
        Map<String, dynamic> json) =>
    _$ApproveTransactionDataImpl(
      data: json['data'] as String,
      dexContractAddress: json['dexContractAddress'] as String,
      gasLimit: json['gasLimit'] as String,
      gasPrice: json['gasPrice'] as String,
    );

Map<String, dynamic> _$$ApproveTransactionDataImplToJson(
        _$ApproveTransactionDataImpl instance) =>
    <String, dynamic>{
      'data': instance.data,
      'dexContractAddress': instance.dexContractAddress,
      'gasLimit': instance.gasLimit,
      'gasPrice': instance.gasPrice,
    };

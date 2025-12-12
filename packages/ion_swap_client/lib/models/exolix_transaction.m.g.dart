// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exolix_transaction.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExolixTransactionImpl _$$ExolixTransactionImplFromJson(
        Map<String, dynamic> json) =>
    _$ExolixTransactionImpl(
      id: json['id'] as String,
      amount: json['amount'] as num,
      status: $enumDecode(_$TransactionStatusEnumMap, json['status']),
      depositAddress: json['depositAddress'] as String,
    );

Map<String, dynamic> _$$ExolixTransactionImplToJson(
        _$ExolixTransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'status': _$TransactionStatusEnumMap[instance.status]!,
      'depositAddress': instance.depositAddress,
    };

const _$TransactionStatusEnumMap = {
  TransactionStatus.wait: 'wait',
  TransactionStatus.confirmation: 'confirmation',
  TransactionStatus.confirmed: 'confirmed',
  TransactionStatus.exchanging: 'exchanging',
  TransactionStatus.sending: 'sending',
  TransactionStatus.success: 'success',
  TransactionStatus.overdue: 'overdue',
  TransactionStatus.refunded: 'refunded',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lets_exchange_transaction.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LetsExchangeTransactionImpl _$$LetsExchangeTransactionImplFromJson(
        Map<String, dynamic> json) =>
    _$LetsExchangeTransactionImpl(
      transactionId: json['transaction_id'] as String,
      depositAmount: json['deposit_amount'] as String,
      deposit: json['deposit'] as String,
    );

Map<String, dynamic> _$$LetsExchangeTransactionImplToJson(
        _$LetsExchangeTransactionImpl instance) =>
    <String, dynamic>{
      'transaction_id': instance.transactionId,
      'deposit_amount': instance.depositAmount,
      'deposit': instance.deposit,
    };

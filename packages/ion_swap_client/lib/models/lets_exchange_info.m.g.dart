// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lets_exchange_info.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LetsExchangeInfoImpl _$$LetsExchangeInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$LetsExchangeInfoImpl(
      rateId: json['rate_id'] as String,
      minAmount: json['min_amount'] as String,
      maxAmount: json['max_amount'] as String,
      amount: json['amount'] as String,
      fee: json['fee'] as String,
      rate: json['rate'] as String,
      profit: json['profit'] as String,
      withdrawalFee: json['withdrawal_fee'] as String,
      extraFeeAmount: json['extra_fee_amount'] as String,
    );

Map<String, dynamic> _$$LetsExchangeInfoImplToJson(
        _$LetsExchangeInfoImpl instance) =>
    <String, dynamic>{
      'rate_id': instance.rateId,
      'min_amount': instance.minAmount,
      'max_amount': instance.maxAmount,
      'amount': instance.amount,
      'fee': instance.fee,
      'rate': instance.rate,
      'profit': instance.profit,
      'withdrawal_fee': instance.withdrawalFee,
      'extra_fee_amount': instance.extraFeeAmount,
    };

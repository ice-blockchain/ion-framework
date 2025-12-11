// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swap_coin_parameters.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SwapCoinParametersImpl _$$SwapCoinParametersImplFromJson(
        Map<String, dynamic> json) =>
    _$SwapCoinParametersImpl(
      userSellAddress: json['userSellAddress'] as String?,
      userBuyAddress: json['userBuyAddress'] as String?,
      amount: json['amount'] as String,
      isBridge: json['isBridge'] as bool,
      sellCoin: SwapCoin.fromJson(json['sellCoin'] as Map<String, dynamic>),
      buyCoin: SwapCoin.fromJson(json['buyCoin'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$SwapCoinParametersImplToJson(
        _$SwapCoinParametersImpl instance) =>
    <String, dynamic>{
      'userSellAddress': instance.userSellAddress,
      'userBuyAddress': instance.userBuyAddress,
      'amount': instance.amount,
      'isBridge': instance.isBridge,
      'sellCoin': instance.sellCoin,
      'buyCoin': instance.buyCoin,
    };

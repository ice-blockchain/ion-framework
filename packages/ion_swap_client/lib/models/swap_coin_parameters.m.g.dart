// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swap_coin_parameters.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SwapCoinParametersImpl _$$SwapCoinParametersImplFromJson(
        Map<String, dynamic> json) =>
    _$SwapCoinParametersImpl(
      sellNetworkId: json['sellNetworkId'] as String,
      buyNetworkId: json['buyNetworkId'] as String,
      userSellAddress: json['userSellAddress'] as String?,
      userBuyAddress: json['userBuyAddress'] as String?,
      sellCoinContractAddress: json['sellCoinContractAddress'] as String,
      buyCoinContractAddress: json['buyCoinContractAddress'] as String,
      sellCoinNetworkName: json['sellCoinNetworkName'] as String,
      buyCoinNetworkName: json['buyCoinNetworkName'] as String,
      amount: json['amount'] as String,
      isBridge: json['isBridge'] as bool,
      sellCoinCode: json['sellCoinCode'] as String,
      buyCoinCode: json['buyCoinCode'] as String,
      buyExtraId: json['buyExtraId'] as String,
    );

Map<String, dynamic> _$$SwapCoinParametersImplToJson(
        _$SwapCoinParametersImpl instance) =>
    <String, dynamic>{
      'sellNetworkId': instance.sellNetworkId,
      'buyNetworkId': instance.buyNetworkId,
      'userSellAddress': instance.userSellAddress,
      'userBuyAddress': instance.userBuyAddress,
      'sellCoinContractAddress': instance.sellCoinContractAddress,
      'buyCoinContractAddress': instance.buyCoinContractAddress,
      'sellCoinNetworkName': instance.sellCoinNetworkName,
      'buyCoinNetworkName': instance.buyCoinNetworkName,
      'amount': instance.amount,
      'isBridge': instance.isBridge,
      'sellCoinCode': instance.sellCoinCode,
      'buyCoinCode': instance.buyCoinCode,
      'buyExtraId': instance.buyExtraId,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swap_coin.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SwapCoinImpl _$$SwapCoinImplFromJson(Map<String, dynamic> json) => _$SwapCoinImpl(
      contractAddress: json['contractAddress'] as String,
      code: json['code'] as String,
      decimal: (json['decimal'] as num).toInt(),
      network: SwapNetwork.fromJson(json['network'] as Map<String, dynamic>),
      extraId: json['extraId'] as String,
    );

Map<String, dynamic> _$$SwapCoinImplToJson(_$SwapCoinImpl instance) => <String, dynamic>{
      'contractAddress': instance.contractAddress,
      'code': instance.code,
      'decimal': instance.decimal,
      'network': instance.network,
      'extraId': instance.extraId,
    };

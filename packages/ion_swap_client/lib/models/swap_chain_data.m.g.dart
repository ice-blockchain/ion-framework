// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swap_chain_data.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SwapChainDataImpl _$$SwapChainDataImplFromJson(Map<String, dynamic> json) =>
    _$SwapChainDataImpl(
      chainIndex: (json['chainIndex'] as num).toInt(),
      chainName: json['chainName'] as String,
      dexTokenApproveAddress: json['dexTokenApproveAddress'] as String,
    );

Map<String, dynamic> _$$SwapChainDataImplToJson(_$SwapChainDataImpl instance) =>
    <String, dynamic>{
      'chainIndex': instance.chainIndex,
      'chainName': instance.chainName,
      'dexTokenApproveAddress': instance.dexTokenApproveAddress,
    };

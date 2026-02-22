// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'okx_fee_address.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OkxFeeAddressImpl _$$OkxFeeAddressImplFromJson(Map<String, dynamic> json) =>
    _$OkxFeeAddressImpl(
      avalanceAddress: json['avalanceAddress'] as String,
      arbitrumAddress: json['arbitrumAddress'] as String,
      optimistAddress: json['optimistAddress'] as String,
      polygonAddress: json['polygonAddress'] as String,
      solAddress: json['solAddress'] as String,
      baseAddress: json['baseAddress'] as String,
      tonAddress: json['tonAddress'] as String,
      tronAddress: json['tronAddress'] as String,
      ethAddress: json['ethAddress'] as String,
      bnbAddress: json['bnbAddress'] as String,
    );

Map<String, dynamic> _$$OkxFeeAddressImplToJson(_$OkxFeeAddressImpl instance) =>
    <String, dynamic>{
      'avalanceAddress': instance.avalanceAddress,
      'arbitrumAddress': instance.arbitrumAddress,
      'optimistAddress': instance.optimistAddress,
      'polygonAddress': instance.polygonAddress,
      'solAddress': instance.solAddress,
      'baseAddress': instance.baseAddress,
      'tonAddress': instance.tonAddress,
      'tronAddress': instance.tronAddress,
      'ethAddress': instance.ethAddress,
      'bnbAddress': instance.bnbAddress,
    };

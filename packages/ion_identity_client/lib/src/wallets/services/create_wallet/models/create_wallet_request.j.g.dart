// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_wallet_request.j.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateWalletRequest _$CreateWalletRequestFromJson(Map<String, dynamic> json) =>
    CreateWalletRequest(
      network: json['network'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$CreateWalletRequestToJson(
        CreateWalletRequest instance) =>
    <String, dynamic>{
      'network': instance.network,
      'name': instance.name,
    };

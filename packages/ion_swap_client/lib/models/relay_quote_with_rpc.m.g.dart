// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_quote_with_rpc.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RelayQuoteWithRpcImpl _$$RelayQuoteWithRpcImplFromJson(
        Map<String, dynamic> json) =>
    _$RelayQuoteWithRpcImpl(
      details: RelayQuote.fromJson(json['details'] as Map<String, dynamic>),
      rpcUrl: json['rpcUrl'] as String,
    );

Map<String, dynamic> _$$RelayQuoteWithRpcImplToJson(
        _$RelayQuoteWithRpcImpl instance) =>
    <String, dynamic>{
      'details': instance.details,
      'rpcUrl': instance.rpcUrl,
    };

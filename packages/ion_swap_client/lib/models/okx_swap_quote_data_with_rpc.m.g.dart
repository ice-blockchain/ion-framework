// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'okx_swap_quote_data_with_rpc.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OkxSwapQuoteDataWithRpcImpl _$$OkxSwapQuoteDataWithRpcImplFromJson(
        Map<String, dynamic> json) =>
    _$OkxSwapQuoteDataWithRpcImpl(
      swapQuoteData:
          SwapQuoteData.fromJson(json['swapQuoteData'] as Map<String, dynamic>),
      rpcUrl: json['rpcUrl'] as String?,
    );

Map<String, dynamic> _$$OkxSwapQuoteDataWithRpcImplToJson(
        _$OkxSwapQuoteDataWithRpcImpl instance) =>
    <String, dynamic>{
      'swapQuoteData': instance.swapQuoteData,
      'rpcUrl': instance.rpcUrl,
    };

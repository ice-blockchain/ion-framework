// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'okx_swap_response.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OkxSwapResponseImpl _$$OkxSwapResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$OkxSwapResponseImpl(
      tx: OkxSwapTransaction.fromJson(json['tx'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$OkxSwapResponseImplToJson(
        _$OkxSwapResponseImpl instance) =>
    <String, dynamic>{
      'tx': instance.tx,
    };

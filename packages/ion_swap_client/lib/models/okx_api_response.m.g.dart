// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'okx_api_response.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OkxApiResponseImpl<T> _$$OkxApiResponseImplFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    _$OkxApiResponseImpl<T>(
      code: json['code'] as String,
      data: fromJsonT(json['data']),
    );

Map<String, dynamic> _$$OkxApiResponseImplToJson<T>(
  _$OkxApiResponseImpl<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'code': instance.code,
      'data': toJsonT(instance.data),
    };

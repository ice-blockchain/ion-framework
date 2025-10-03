// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_fee.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NetworkFeeImpl _$$NetworkFeeImplFromJson(Map<String, dynamic> json) =>
    _$NetworkFeeImpl(
      maxFeePerGas:
          const NumberToStringConverter().fromJson(json['maxFeePerGas']),
      maxPriorityFeePerGas: const NumberToStringConverter()
          .fromJson(json['maxPriorityFeePerGas']),
      feeRate: const NumberToStringConverter().fromJson(json['feeRate']),
      waitTime: _$JsonConverterFromJson<int, Duration>(
          json['waitTime'], const DurationConverter().fromJson),
    );

Map<String, dynamic> _$$NetworkFeeImplToJson(_$NetworkFeeImpl instance) =>
    <String, dynamic>{
      if (_$JsonConverterToJson<dynamic, String>(
              instance.maxFeePerGas, const NumberToStringConverter().toJson)
          case final value?)
        'maxFeePerGas': value,
      if (_$JsonConverterToJson<dynamic, String>(instance.maxPriorityFeePerGas,
              const NumberToStringConverter().toJson)
          case final value?)
        'maxPriorityFeePerGas': value,
      if (_$JsonConverterToJson<dynamic, String>(
              instance.feeRate, const NumberToStringConverter().toJson)
          case final value?)
        'feeRate': value,
      if (_$JsonConverterToJson<int, Duration>(
              instance.waitTime, const DurationConverter().toJson)
          case final value?)
        'waitTime': value,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);

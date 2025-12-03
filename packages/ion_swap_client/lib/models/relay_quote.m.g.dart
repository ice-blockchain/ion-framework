// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_quote.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RelayQuoteImpl _$$RelayQuoteImplFromJson(Map<String, dynamic> json) =>
    _$RelayQuoteImpl(
      details:
          RelayQuoteDetails.fromJson(json['details'] as Map<String, dynamic>),
      steps: (json['steps'] as List<dynamic>)
          .map((e) => RelayStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$RelayQuoteImplToJson(_$RelayQuoteImpl instance) =>
    <String, dynamic>{
      'details': instance.details,
      'steps': instance.steps,
    };

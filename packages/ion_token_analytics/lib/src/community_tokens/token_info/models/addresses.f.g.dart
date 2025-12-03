// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'addresses.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AddressesImpl _$$AddressesImplFromJson(Map<String, dynamic> json) =>
    _$AddressesImpl(
      blockchain: json['blockchain'] as String,
      ionConnect: json['ionConnect'] as String,
    );

Map<String, dynamic> _$$AddressesImplToJson(_$AddressesImpl instance) =>
    <String, dynamic>{
      'blockchain': instance.blockchain,
      'ionConnect': instance.ionConnect,
    };

_$AddressesPatchImpl _$$AddressesPatchImplFromJson(Map<String, dynamic> json) =>
    _$AddressesPatchImpl(
      blockchain: json['blockchain'] as String?,
      ionConnect: json['ionConnect'] as String?,
    );

Map<String, dynamic> _$$AddressesPatchImplToJson(
  _$AddressesPatchImpl instance,
) => <String, dynamic>{
  if (instance.blockchain case final value?) 'blockchain': value,
  if (instance.ionConnect case final value?) 'ionConnect': value,
};

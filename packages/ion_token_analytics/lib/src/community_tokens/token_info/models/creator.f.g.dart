// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creator.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CreatorImpl _$$CreatorImplFromJson(Map<String, dynamic> json) =>
    _$CreatorImpl(
      name: json['name'] as String,
      display: json['display'] as String,
      verified: json['verified'] as bool,
      avatar: json['avatar'] as String?,
      addresses: json['addresses'] == null
          ? null
          : Addresses.fromJson(json['addresses'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$CreatorImplToJson(_$CreatorImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'display': instance.display,
      'verified': instance.verified,
      if (instance.avatar case final value?) 'avatar': value,
      if (instance.addresses?.toJson() case final value?) 'addresses': value,
    };

_$CreatorPatchImpl _$$CreatorPatchImplFromJson(Map<String, dynamic> json) =>
    _$CreatorPatchImpl(
      name: json['name'] as String?,
      display: json['display'] as String?,
      verified: json['verified'] as bool?,
      avatar: json['avatar'] as String?,
      addresses: json['addresses'] == null
          ? null
          : AddressesPatch.fromJson(json['addresses'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$CreatorPatchImplToJson(_$CreatorPatchImpl instance) =>
    <String, dynamic>{
      if (instance.name case final value?) 'name': value,
      if (instance.display case final value?) 'display': value,
      if (instance.verified case final value?) 'verified': value,
      if (instance.avatar case final value?) 'avatar': value,
      if (instance.addresses?.toJson() case final value?) 'addresses': value,
    };

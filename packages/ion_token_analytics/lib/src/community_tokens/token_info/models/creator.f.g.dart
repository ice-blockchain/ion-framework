// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creator.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CreatorImpl _$$CreatorImplFromJson(Map<String, dynamic> json) =>
    _$CreatorImpl(
      display: json['display'] as String?,
      verified: json['verified'] as bool?,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      addresses: json['addresses'] == null
          ? null
          : Addresses.fromJson(json['addresses'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$CreatorImplToJson(_$CreatorImpl instance) =>
    <String, dynamic>{
      if (instance.display case final value?) 'display': value,
      if (instance.verified case final value?) 'verified': value,
      if (instance.name case final value?) 'name': value,
      if (instance.avatar case final value?) 'avatar': value,
      if (instance.addresses?.toJson() case final value?) 'addresses': value,
    };

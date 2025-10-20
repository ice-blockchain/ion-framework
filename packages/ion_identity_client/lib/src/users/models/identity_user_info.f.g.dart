// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_user_info.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IdentityUserInfoImpl _$$IdentityUserInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$IdentityUserInfoImpl(
      masterPubKey: json['masterPubKey'] as String,
      ionConnectRelays: (json['ionConnectRelays'] as List<dynamic>)
          .map((e) => IonConnectRelayInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$$IdentityUserInfoImplToJson(
        _$IdentityUserInfoImpl instance) =>
    <String, dynamic>{
      'masterPubKey': instance.masterPubKey,
      'ionConnectRelays':
          instance.ionConnectRelays.map((e) => e.toJson()).toList(),
      'username': instance.username,
      'displayName': instance.displayName,
      if (instance.avatar case final value?) 'avatar': value,
    };

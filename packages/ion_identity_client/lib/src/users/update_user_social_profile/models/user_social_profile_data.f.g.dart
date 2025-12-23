// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_social_profile_data.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserSocialProfileDataImpl _$$UserSocialProfileDataImplFromJson(
        Map<String, dynamic> json) =>
    _$UserSocialProfileDataImpl(
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      referral: json['referral'] as String?,
      referralMasterKey: json['referralMasterKey'] as String?,
      referralCount: (json['referralCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$UserSocialProfileDataImplToJson(
        _$UserSocialProfileDataImpl instance) =>
    <String, dynamic>{
      if (instance.username case final value?) 'username': value,
      if (instance.displayName case final value?) 'displayName': value,
      if (instance.avatar case final value?) 'avatar': value,
      if (instance.bio case final value?) 'bio': value,
      if (instance.referral case final value?) 'referral': value,
      if (instance.referralMasterKey case final value?)
        'referralMasterKey': value,
      if (instance.referralCount case final value?) 'referralCount': value,
    };

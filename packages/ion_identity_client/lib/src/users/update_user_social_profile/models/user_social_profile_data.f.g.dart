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
    );

Map<String, dynamic> _$$UserSocialProfileDataImplToJson(
    _$UserSocialProfileDataImpl instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('username', instance.username);
  writeNotNull('displayName', instance.displayName);
  writeNotNull('avatar', instance.avatar);
  writeNotNull('bio', instance.bio);
  writeNotNull('referral', instance.referral);
  return val;
}

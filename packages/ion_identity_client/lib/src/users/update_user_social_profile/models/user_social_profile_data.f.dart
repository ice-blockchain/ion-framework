// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_social_profile_data.f.freezed.dart';
part 'user_social_profile_data.f.g.dart';

@freezed
class UserSocialProfileData with _$UserSocialProfileData {
  @JsonSerializable(includeIfNull: false)
  const factory UserSocialProfileData({
    String? username,
    String? displayName,
    String? avatar,
    String? bio,
    String? referral,
    int? referralCount,
  }) = _UserSocialProfileData;

  factory UserSocialProfileData.fromJson(Map<String, dynamic> json) =>
      _$UserSocialProfileDataFromJson(json);
}

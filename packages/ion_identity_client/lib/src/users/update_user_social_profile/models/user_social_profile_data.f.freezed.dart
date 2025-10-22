// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_social_profile_data.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserSocialProfileData _$UserSocialProfileDataFromJson(Map<String, dynamic> json) {
  return _UserSocialProfileData.fromJson(json);
}

/// @nodoc
mixin _$UserSocialProfileData {
  String? get username => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get avatar => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  String? get referral => throw _privateConstructorUsedError;
  int? get referralCount => throw _privateConstructorUsedError;

  /// Serializes this UserSocialProfileData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserSocialProfileData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserSocialProfileDataCopyWith<UserSocialProfileData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSocialProfileDataCopyWith<$Res> {
  factory $UserSocialProfileDataCopyWith(
          UserSocialProfileData value, $Res Function(UserSocialProfileData) then) =
      _$UserSocialProfileDataCopyWithImpl<$Res, UserSocialProfileData>;
  @useResult
  $Res call(
      {String? username,
      String? displayName,
      String? avatar,
      String? bio,
      String? referral,
      int? referralCount});
}

/// @nodoc
class _$UserSocialProfileDataCopyWithImpl<$Res, $Val extends UserSocialProfileData>
    implements $UserSocialProfileDataCopyWith<$Res> {
  _$UserSocialProfileDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserSocialProfileData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = freezed,
    Object? displayName = freezed,
    Object? avatar = freezed,
    Object? bio = freezed,
    Object? referral = freezed,
    Object? referralCount = freezed,
  }) {
    return _then(_value.copyWith(
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      referral: freezed == referral
          ? _value.referral
          : referral // ignore: cast_nullable_to_non_nullable
              as String?,
      referralCount: freezed == referralCount
          ? _value.referralCount
          : referralCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSocialProfileDataImplCopyWith<$Res>
    implements $UserSocialProfileDataCopyWith<$Res> {
  factory _$$UserSocialProfileDataImplCopyWith(
          _$UserSocialProfileDataImpl value, $Res Function(_$UserSocialProfileDataImpl) then) =
      __$$UserSocialProfileDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? username,
      String? displayName,
      String? avatar,
      String? bio,
      String? referral,
      int? referralCount});
}

/// @nodoc
class __$$UserSocialProfileDataImplCopyWithImpl<$Res>
    extends _$UserSocialProfileDataCopyWithImpl<$Res, _$UserSocialProfileDataImpl>
    implements _$$UserSocialProfileDataImplCopyWith<$Res> {
  __$$UserSocialProfileDataImplCopyWithImpl(
      _$UserSocialProfileDataImpl _value, $Res Function(_$UserSocialProfileDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserSocialProfileData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = freezed,
    Object? displayName = freezed,
    Object? avatar = freezed,
    Object? bio = freezed,
    Object? referral = freezed,
    Object? referralCount = freezed,
  }) {
    return _then(_$UserSocialProfileDataImpl(
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      referral: freezed == referral
          ? _value.referral
          : referral // ignore: cast_nullable_to_non_nullable
              as String?,
      referralCount: freezed == referralCount
          ? _value.referralCount
          : referralCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _$UserSocialProfileDataImpl implements _UserSocialProfileData {
  const _$UserSocialProfileDataImpl(
      {this.username, this.displayName, this.avatar, this.bio, this.referral, this.referralCount});

  factory _$UserSocialProfileDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSocialProfileDataImplFromJson(json);

  @override
  final String? username;
  @override
  final String? displayName;
  @override
  final String? avatar;
  @override
  final String? bio;
  @override
  final String? referral;
  @override
  final int? referralCount;

  @override
  String toString() {
    return 'UserSocialProfileData(username: $username, displayName: $displayName, avatar: $avatar, bio: $bio, referral: $referral, referralCount: $referralCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSocialProfileDataImpl &&
            (identical(other.username, username) || other.username == username) &&
            (identical(other.displayName, displayName) || other.displayName == displayName) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.referral, referral) || other.referral == referral) &&
            (identical(other.referralCount, referralCount) ||
                other.referralCount == referralCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, username, displayName, avatar, bio, referral, referralCount);

  /// Create a copy of UserSocialProfileData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSocialProfileDataImplCopyWith<_$UserSocialProfileDataImpl> get copyWith =>
      __$$UserSocialProfileDataImplCopyWithImpl<_$UserSocialProfileDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSocialProfileDataImplToJson(
      this,
    );
  }
}

abstract class _UserSocialProfileData implements UserSocialProfileData {
  const factory _UserSocialProfileData(
      {final String? username,
      final String? displayName,
      final String? avatar,
      final String? bio,
      final String? referral,
      final int? referralCount}) = _$UserSocialProfileDataImpl;

  factory _UserSocialProfileData.fromJson(Map<String, dynamic> json) =
      _$UserSocialProfileDataImpl.fromJson;

  @override
  String? get username;
  @override
  String? get displayName;
  @override
  String? get avatar;
  @override
  String? get bio;
  @override
  String? get referral;
  @override
  int? get referralCount;

  /// Create a copy of UserSocialProfileData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserSocialProfileDataImplCopyWith<_$UserSocialProfileDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

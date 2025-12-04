// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'okx_token_info.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OkxTokenInfo _$OkxTokenInfoFromJson(Map<String, dynamic> json) {
  return _OkxTokenInfo.fromJson(json);
}

/// @nodoc
mixin _$OkxTokenInfo {
  String get decimal => throw _privateConstructorUsedError;

  /// Serializes this OkxTokenInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OkxTokenInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OkxTokenInfoCopyWith<OkxTokenInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OkxTokenInfoCopyWith<$Res> {
  factory $OkxTokenInfoCopyWith(
          OkxTokenInfo value, $Res Function(OkxTokenInfo) then) =
      _$OkxTokenInfoCopyWithImpl<$Res, OkxTokenInfo>;
  @useResult
  $Res call({String decimal});
}

/// @nodoc
class _$OkxTokenInfoCopyWithImpl<$Res, $Val extends OkxTokenInfo>
    implements $OkxTokenInfoCopyWith<$Res> {
  _$OkxTokenInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OkxTokenInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? decimal = null,
  }) {
    return _then(_value.copyWith(
      decimal: null == decimal
          ? _value.decimal
          : decimal // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OkxTokenInfoImplCopyWith<$Res>
    implements $OkxTokenInfoCopyWith<$Res> {
  factory _$$OkxTokenInfoImplCopyWith(
          _$OkxTokenInfoImpl value, $Res Function(_$OkxTokenInfoImpl) then) =
      __$$OkxTokenInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String decimal});
}

/// @nodoc
class __$$OkxTokenInfoImplCopyWithImpl<$Res>
    extends _$OkxTokenInfoCopyWithImpl<$Res, _$OkxTokenInfoImpl>
    implements _$$OkxTokenInfoImplCopyWith<$Res> {
  __$$OkxTokenInfoImplCopyWithImpl(
      _$OkxTokenInfoImpl _value, $Res Function(_$OkxTokenInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of OkxTokenInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? decimal = null,
  }) {
    return _then(_$OkxTokenInfoImpl(
      decimal: null == decimal
          ? _value.decimal
          : decimal // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OkxTokenInfoImpl implements _OkxTokenInfo {
  _$OkxTokenInfoImpl({required this.decimal});

  factory _$OkxTokenInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$OkxTokenInfoImplFromJson(json);

  @override
  final String decimal;

  @override
  String toString() {
    return 'OkxTokenInfo(decimal: $decimal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OkxTokenInfoImpl &&
            (identical(other.decimal, decimal) || other.decimal == decimal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, decimal);

  /// Create a copy of OkxTokenInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OkxTokenInfoImplCopyWith<_$OkxTokenInfoImpl> get copyWith =>
      __$$OkxTokenInfoImplCopyWithImpl<_$OkxTokenInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OkxTokenInfoImplToJson(
      this,
    );
  }
}

abstract class _OkxTokenInfo implements OkxTokenInfo {
  factory _OkxTokenInfo({required final String decimal}) = _$OkxTokenInfoImpl;

  factory _OkxTokenInfo.fromJson(Map<String, dynamic> json) =
      _$OkxTokenInfoImpl.fromJson;

  @override
  String get decimal;

  /// Create a copy of OkxTokenInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OkxTokenInfoImplCopyWith<_$OkxTokenInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

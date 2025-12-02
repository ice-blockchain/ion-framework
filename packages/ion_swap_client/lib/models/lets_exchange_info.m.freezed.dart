// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lets_exchange_info.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LetsExchangeInfo _$LetsExchangeInfoFromJson(Map<String, dynamic> json) {
  return _LetsExchangeInfo.fromJson(json);
}

/// @nodoc
mixin _$LetsExchangeInfo {
  @JsonKey(name: 'rate_id')
  String get rateId => throw _privateConstructorUsedError;

  /// Serializes this LetsExchangeInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LetsExchangeInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LetsExchangeInfoCopyWith<LetsExchangeInfo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LetsExchangeInfoCopyWith<$Res> {
  factory $LetsExchangeInfoCopyWith(LetsExchangeInfo value, $Res Function(LetsExchangeInfo) then) =
      _$LetsExchangeInfoCopyWithImpl<$Res, LetsExchangeInfo>;
  @useResult
  $Res call({@JsonKey(name: 'rate_id') String rateId});
}

/// @nodoc
class _$LetsExchangeInfoCopyWithImpl<$Res, $Val extends LetsExchangeInfo>
    implements $LetsExchangeInfoCopyWith<$Res> {
  _$LetsExchangeInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LetsExchangeInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rateId = null,
  }) {
    return _then(_value.copyWith(
      rateId: null == rateId
          ? _value.rateId
          : rateId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LetsExchangeInfoImplCopyWith<$Res> implements $LetsExchangeInfoCopyWith<$Res> {
  factory _$$LetsExchangeInfoImplCopyWith(
          _$LetsExchangeInfoImpl value, $Res Function(_$LetsExchangeInfoImpl) then) =
      __$$LetsExchangeInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'rate_id') String rateId});
}

/// @nodoc
class __$$LetsExchangeInfoImplCopyWithImpl<$Res>
    extends _$LetsExchangeInfoCopyWithImpl<$Res, _$LetsExchangeInfoImpl>
    implements _$$LetsExchangeInfoImplCopyWith<$Res> {
  __$$LetsExchangeInfoImplCopyWithImpl(
      _$LetsExchangeInfoImpl _value, $Res Function(_$LetsExchangeInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of LetsExchangeInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rateId = null,
  }) {
    return _then(_$LetsExchangeInfoImpl(
      rateId: null == rateId
          ? _value.rateId
          : rateId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LetsExchangeInfoImpl implements _LetsExchangeInfo {
  _$LetsExchangeInfoImpl({@JsonKey(name: 'rate_id') required this.rateId});

  factory _$LetsExchangeInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$LetsExchangeInfoImplFromJson(json);

  @override
  @JsonKey(name: 'rate_id')
  final String rateId;

  @override
  String toString() {
    return 'LetsExchangeInfo(rateId: $rateId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LetsExchangeInfoImpl &&
            (identical(other.rateId, rateId) || other.rateId == rateId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, rateId);

  /// Create a copy of LetsExchangeInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LetsExchangeInfoImplCopyWith<_$LetsExchangeInfoImpl> get copyWith =>
      __$$LetsExchangeInfoImplCopyWithImpl<_$LetsExchangeInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LetsExchangeInfoImplToJson(
      this,
    );
  }
}

abstract class _LetsExchangeInfo implements LetsExchangeInfo {
  factory _LetsExchangeInfo({@JsonKey(name: 'rate_id') required final String rateId}) =
      _$LetsExchangeInfoImpl;

  factory _LetsExchangeInfo.fromJson(Map<String, dynamic> json) = _$LetsExchangeInfoImpl.fromJson;

  @override
  @JsonKey(name: 'rate_id')
  String get rateId;

  /// Create a copy of LetsExchangeInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LetsExchangeInfoImplCopyWith<_$LetsExchangeInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lets_exchange_error.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LetsExchangeError _$LetsExchangeErrorFromJson(Map<String, dynamic> json) {
  return _LetsExchangeError.fromJson(json);
}

/// @nodoc
mixin _$LetsExchangeError {
  bool get success => throw _privateConstructorUsedError;
  String get error => throw _privateConstructorUsedError;

  /// Serializes this LetsExchangeError to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LetsExchangeError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LetsExchangeErrorCopyWith<LetsExchangeError> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LetsExchangeErrorCopyWith<$Res> {
  factory $LetsExchangeErrorCopyWith(
          LetsExchangeError value, $Res Function(LetsExchangeError) then) =
      _$LetsExchangeErrorCopyWithImpl<$Res, LetsExchangeError>;
  @useResult
  $Res call({bool success, String error});
}

/// @nodoc
class _$LetsExchangeErrorCopyWithImpl<$Res, $Val extends LetsExchangeError>
    implements $LetsExchangeErrorCopyWith<$Res> {
  _$LetsExchangeErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LetsExchangeError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? error = null,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      error: null == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LetsExchangeErrorImplCopyWith<$Res>
    implements $LetsExchangeErrorCopyWith<$Res> {
  factory _$$LetsExchangeErrorImplCopyWith(_$LetsExchangeErrorImpl value,
          $Res Function(_$LetsExchangeErrorImpl) then) =
      __$$LetsExchangeErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool success, String error});
}

/// @nodoc
class __$$LetsExchangeErrorImplCopyWithImpl<$Res>
    extends _$LetsExchangeErrorCopyWithImpl<$Res, _$LetsExchangeErrorImpl>
    implements _$$LetsExchangeErrorImplCopyWith<$Res> {
  __$$LetsExchangeErrorImplCopyWithImpl(_$LetsExchangeErrorImpl _value,
      $Res Function(_$LetsExchangeErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of LetsExchangeError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? error = null,
  }) {
    return _then(_$LetsExchangeErrorImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      error: null == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LetsExchangeErrorImpl implements _LetsExchangeError {
  _$LetsExchangeErrorImpl({required this.success, required this.error});

  factory _$LetsExchangeErrorImpl.fromJson(Map<String, dynamic> json) =>
      _$$LetsExchangeErrorImplFromJson(json);

  @override
  final bool success;
  @override
  final String error;

  @override
  String toString() {
    return 'LetsExchangeError(success: $success, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LetsExchangeErrorImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, success, error);

  /// Create a copy of LetsExchangeError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LetsExchangeErrorImplCopyWith<_$LetsExchangeErrorImpl> get copyWith =>
      __$$LetsExchangeErrorImplCopyWithImpl<_$LetsExchangeErrorImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LetsExchangeErrorImplToJson(
      this,
    );
  }
}

abstract class _LetsExchangeError implements LetsExchangeError {
  factory _LetsExchangeError(
      {required final bool success,
      required final String error}) = _$LetsExchangeErrorImpl;

  factory _LetsExchangeError.fromJson(Map<String, dynamic> json) =
      _$LetsExchangeErrorImpl.fromJson;

  @override
  bool get success;
  @override
  String get error;

  /// Create a copy of LetsExchangeError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LetsExchangeErrorImplCopyWith<_$LetsExchangeErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

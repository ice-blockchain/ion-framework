// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exolix_error.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExolixError _$ExolixErrorFromJson(Map<String, dynamic> json) {
  return _ExolixError.fromJson(json);
}

/// @nodoc
mixin _$ExolixError {
  num get fromAmount => throw _privateConstructorUsedError;
  num get toAmount => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  num get minAmount => throw _privateConstructorUsedError;

  /// Serializes this ExolixError to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExolixError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExolixErrorCopyWith<ExolixError> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExolixErrorCopyWith<$Res> {
  factory $ExolixErrorCopyWith(
          ExolixError value, $Res Function(ExolixError) then) =
      _$ExolixErrorCopyWithImpl<$Res, ExolixError>;
  @useResult
  $Res call({num fromAmount, num toAmount, String message, num minAmount});
}

/// @nodoc
class _$ExolixErrorCopyWithImpl<$Res, $Val extends ExolixError>
    implements $ExolixErrorCopyWith<$Res> {
  _$ExolixErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExolixError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromAmount = null,
    Object? toAmount = null,
    Object? message = null,
    Object? minAmount = null,
  }) {
    return _then(_value.copyWith(
      fromAmount: null == fromAmount
          ? _value.fromAmount
          : fromAmount // ignore: cast_nullable_to_non_nullable
              as num,
      toAmount: null == toAmount
          ? _value.toAmount
          : toAmount // ignore: cast_nullable_to_non_nullable
              as num,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      minAmount: null == minAmount
          ? _value.minAmount
          : minAmount // ignore: cast_nullable_to_non_nullable
              as num,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExolixErrorImplCopyWith<$Res>
    implements $ExolixErrorCopyWith<$Res> {
  factory _$$ExolixErrorImplCopyWith(
          _$ExolixErrorImpl value, $Res Function(_$ExolixErrorImpl) then) =
      __$$ExolixErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({num fromAmount, num toAmount, String message, num minAmount});
}

/// @nodoc
class __$$ExolixErrorImplCopyWithImpl<$Res>
    extends _$ExolixErrorCopyWithImpl<$Res, _$ExolixErrorImpl>
    implements _$$ExolixErrorImplCopyWith<$Res> {
  __$$ExolixErrorImplCopyWithImpl(
      _$ExolixErrorImpl _value, $Res Function(_$ExolixErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExolixError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromAmount = null,
    Object? toAmount = null,
    Object? message = null,
    Object? minAmount = null,
  }) {
    return _then(_$ExolixErrorImpl(
      fromAmount: null == fromAmount
          ? _value.fromAmount
          : fromAmount // ignore: cast_nullable_to_non_nullable
              as num,
      toAmount: null == toAmount
          ? _value.toAmount
          : toAmount // ignore: cast_nullable_to_non_nullable
              as num,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      minAmount: null == minAmount
          ? _value.minAmount
          : minAmount // ignore: cast_nullable_to_non_nullable
              as num,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExolixErrorImpl implements _ExolixError {
  _$ExolixErrorImpl(
      {required this.fromAmount,
      required this.toAmount,
      required this.message,
      required this.minAmount});

  factory _$ExolixErrorImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExolixErrorImplFromJson(json);

  @override
  final num fromAmount;
  @override
  final num toAmount;
  @override
  final String message;
  @override
  final num minAmount;

  @override
  String toString() {
    return 'ExolixError(fromAmount: $fromAmount, toAmount: $toAmount, message: $message, minAmount: $minAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExolixErrorImpl &&
            (identical(other.fromAmount, fromAmount) ||
                other.fromAmount == fromAmount) &&
            (identical(other.toAmount, toAmount) ||
                other.toAmount == toAmount) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.minAmount, minAmount) ||
                other.minAmount == minAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, fromAmount, toAmount, message, minAmount);

  /// Create a copy of ExolixError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExolixErrorImplCopyWith<_$ExolixErrorImpl> get copyWith =>
      __$$ExolixErrorImplCopyWithImpl<_$ExolixErrorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExolixErrorImplToJson(
      this,
    );
  }
}

abstract class _ExolixError implements ExolixError {
  factory _ExolixError(
      {required final num fromAmount,
      required final num toAmount,
      required final String message,
      required final num minAmount}) = _$ExolixErrorImpl;

  factory _ExolixError.fromJson(Map<String, dynamic> json) =
      _$ExolixErrorImpl.fromJson;

  @override
  num get fromAmount;
  @override
  num get toAmount;
  @override
  String get message;
  @override
  num get minAmount;

  /// Create a copy of ExolixError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExolixErrorImplCopyWith<_$ExolixErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

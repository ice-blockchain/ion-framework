// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exolix_rate.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExolixRate _$ExolixRateFromJson(Map<String, dynamic> json) {
  return _ExolixRate.fromJson(json);
}

/// @nodoc
mixin _$ExolixRate {
  num get fromAmount => throw _privateConstructorUsedError;
  num get toAmount => throw _privateConstructorUsedError;
  num get rate => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  num get minAmount => throw _privateConstructorUsedError;
  num get withdrawMin => throw _privateConstructorUsedError;
  num get maxAmount => throw _privateConstructorUsedError;

  /// Serializes this ExolixRate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExolixRate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExolixRateCopyWith<ExolixRate> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExolixRateCopyWith<$Res> {
  factory $ExolixRateCopyWith(ExolixRate value, $Res Function(ExolixRate) then) =
      _$ExolixRateCopyWithImpl<$Res, ExolixRate>;
  @useResult
  $Res call(
      {num fromAmount,
      num toAmount,
      num rate,
      String? message,
      num minAmount,
      num withdrawMin,
      num maxAmount});
}

/// @nodoc
class _$ExolixRateCopyWithImpl<$Res, $Val extends ExolixRate> implements $ExolixRateCopyWith<$Res> {
  _$ExolixRateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExolixRate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromAmount = null,
    Object? toAmount = null,
    Object? rate = null,
    Object? message = freezed,
    Object? minAmount = null,
    Object? withdrawMin = null,
    Object? maxAmount = null,
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
      rate: null == rate
          ? _value.rate
          : rate // ignore: cast_nullable_to_non_nullable
              as num,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      minAmount: null == minAmount
          ? _value.minAmount
          : minAmount // ignore: cast_nullable_to_non_nullable
              as num,
      withdrawMin: null == withdrawMin
          ? _value.withdrawMin
          : withdrawMin // ignore: cast_nullable_to_non_nullable
              as num,
      maxAmount: null == maxAmount
          ? _value.maxAmount
          : maxAmount // ignore: cast_nullable_to_non_nullable
              as num,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExolixRateImplCopyWith<$Res> implements $ExolixRateCopyWith<$Res> {
  factory _$$ExolixRateImplCopyWith(_$ExolixRateImpl value, $Res Function(_$ExolixRateImpl) then) =
      __$$ExolixRateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {num fromAmount,
      num toAmount,
      num rate,
      String? message,
      num minAmount,
      num withdrawMin,
      num maxAmount});
}

/// @nodoc
class __$$ExolixRateImplCopyWithImpl<$Res> extends _$ExolixRateCopyWithImpl<$Res, _$ExolixRateImpl>
    implements _$$ExolixRateImplCopyWith<$Res> {
  __$$ExolixRateImplCopyWithImpl(_$ExolixRateImpl _value, $Res Function(_$ExolixRateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExolixRate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromAmount = null,
    Object? toAmount = null,
    Object? rate = null,
    Object? message = freezed,
    Object? minAmount = null,
    Object? withdrawMin = null,
    Object? maxAmount = null,
  }) {
    return _then(_$ExolixRateImpl(
      fromAmount: null == fromAmount
          ? _value.fromAmount
          : fromAmount // ignore: cast_nullable_to_non_nullable
              as num,
      toAmount: null == toAmount
          ? _value.toAmount
          : toAmount // ignore: cast_nullable_to_non_nullable
              as num,
      rate: null == rate
          ? _value.rate
          : rate // ignore: cast_nullable_to_non_nullable
              as num,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      minAmount: null == minAmount
          ? _value.minAmount
          : minAmount // ignore: cast_nullable_to_non_nullable
              as num,
      withdrawMin: null == withdrawMin
          ? _value.withdrawMin
          : withdrawMin // ignore: cast_nullable_to_non_nullable
              as num,
      maxAmount: null == maxAmount
          ? _value.maxAmount
          : maxAmount // ignore: cast_nullable_to_non_nullable
              as num,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExolixRateImpl implements _ExolixRate {
  _$ExolixRateImpl(
      {required this.fromAmount,
      required this.toAmount,
      required this.rate,
      required this.message,
      required this.minAmount,
      required this.withdrawMin,
      required this.maxAmount});

  factory _$ExolixRateImpl.fromJson(Map<String, dynamic> json) => _$$ExolixRateImplFromJson(json);

  @override
  final num fromAmount;
  @override
  final num toAmount;
  @override
  final num rate;
  @override
  final String? message;
  @override
  final num minAmount;
  @override
  final num withdrawMin;
  @override
  final num maxAmount;

  @override
  String toString() {
    return 'ExolixRate(fromAmount: $fromAmount, toAmount: $toAmount, rate: $rate, message: $message, minAmount: $minAmount, withdrawMin: $withdrawMin, maxAmount: $maxAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExolixRateImpl &&
            (identical(other.fromAmount, fromAmount) || other.fromAmount == fromAmount) &&
            (identical(other.toAmount, toAmount) || other.toAmount == toAmount) &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.minAmount, minAmount) || other.minAmount == minAmount) &&
            (identical(other.withdrawMin, withdrawMin) || other.withdrawMin == withdrawMin) &&
            (identical(other.maxAmount, maxAmount) || other.maxAmount == maxAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, fromAmount, toAmount, rate, message, minAmount, withdrawMin, maxAmount);

  /// Create a copy of ExolixRate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExolixRateImplCopyWith<_$ExolixRateImpl> get copyWith =>
      __$$ExolixRateImplCopyWithImpl<_$ExolixRateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExolixRateImplToJson(
      this,
    );
  }
}

abstract class _ExolixRate implements ExolixRate {
  factory _ExolixRate(
      {required final num fromAmount,
      required final num toAmount,
      required final num rate,
      required final String? message,
      required final num minAmount,
      required final num withdrawMin,
      required final num maxAmount}) = _$ExolixRateImpl;

  factory _ExolixRate.fromJson(Map<String, dynamic> json) = _$ExolixRateImpl.fromJson;

  @override
  num get fromAmount;
  @override
  num get toAmount;
  @override
  num get rate;
  @override
  String? get message;
  @override
  num get minAmount;
  @override
  num get withdrawMin;
  @override
  num get maxAmount;

  /// Create a copy of ExolixRate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExolixRateImplCopyWith<_$ExolixRateImpl> get copyWith => throw _privateConstructorUsedError;
}

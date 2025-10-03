// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'network_fee.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NetworkFee _$NetworkFeeFromJson(Map<String, dynamic> json) {
  return _NetworkFee.fromJson(json);
}

/// @nodoc
mixin _$NetworkFee {
  @NumberToStringConverter()
  String? get maxFeePerGas => throw _privateConstructorUsedError;
  @NumberToStringConverter()
  String? get maxPriorityFeePerGas => throw _privateConstructorUsedError;
  @NumberToStringConverter()
  String? get feeRate => throw _privateConstructorUsedError;
  @DurationConverter()
  Duration? get waitTime => throw _privateConstructorUsedError;

  /// Serializes this NetworkFee to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NetworkFee
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NetworkFeeCopyWith<NetworkFee> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetworkFeeCopyWith<$Res> {
  factory $NetworkFeeCopyWith(
          NetworkFee value, $Res Function(NetworkFee) then) =
      _$NetworkFeeCopyWithImpl<$Res, NetworkFee>;
  @useResult
  $Res call(
      {@NumberToStringConverter() String? maxFeePerGas,
      @NumberToStringConverter() String? maxPriorityFeePerGas,
      @NumberToStringConverter() String? feeRate,
      @DurationConverter() Duration? waitTime});
}

/// @nodoc
class _$NetworkFeeCopyWithImpl<$Res, $Val extends NetworkFee>
    implements $NetworkFeeCopyWith<$Res> {
  _$NetworkFeeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NetworkFee
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxFeePerGas = freezed,
    Object? maxPriorityFeePerGas = freezed,
    Object? feeRate = freezed,
    Object? waitTime = freezed,
  }) {
    return _then(_value.copyWith(
      maxFeePerGas: freezed == maxFeePerGas
          ? _value.maxFeePerGas
          : maxFeePerGas // ignore: cast_nullable_to_non_nullable
              as String?,
      maxPriorityFeePerGas: freezed == maxPriorityFeePerGas
          ? _value.maxPriorityFeePerGas
          : maxPriorityFeePerGas // ignore: cast_nullable_to_non_nullable
              as String?,
      feeRate: freezed == feeRate
          ? _value.feeRate
          : feeRate // ignore: cast_nullable_to_non_nullable
              as String?,
      waitTime: freezed == waitTime
          ? _value.waitTime
          : waitTime // ignore: cast_nullable_to_non_nullable
              as Duration?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NetworkFeeImplCopyWith<$Res>
    implements $NetworkFeeCopyWith<$Res> {
  factory _$$NetworkFeeImplCopyWith(
          _$NetworkFeeImpl value, $Res Function(_$NetworkFeeImpl) then) =
      __$$NetworkFeeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@NumberToStringConverter() String? maxFeePerGas,
      @NumberToStringConverter() String? maxPriorityFeePerGas,
      @NumberToStringConverter() String? feeRate,
      @DurationConverter() Duration? waitTime});
}

/// @nodoc
class __$$NetworkFeeImplCopyWithImpl<$Res>
    extends _$NetworkFeeCopyWithImpl<$Res, _$NetworkFeeImpl>
    implements _$$NetworkFeeImplCopyWith<$Res> {
  __$$NetworkFeeImplCopyWithImpl(
      _$NetworkFeeImpl _value, $Res Function(_$NetworkFeeImpl) _then)
      : super(_value, _then);

  /// Create a copy of NetworkFee
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxFeePerGas = freezed,
    Object? maxPriorityFeePerGas = freezed,
    Object? feeRate = freezed,
    Object? waitTime = freezed,
  }) {
    return _then(_$NetworkFeeImpl(
      maxFeePerGas: freezed == maxFeePerGas
          ? _value.maxFeePerGas
          : maxFeePerGas // ignore: cast_nullable_to_non_nullable
              as String?,
      maxPriorityFeePerGas: freezed == maxPriorityFeePerGas
          ? _value.maxPriorityFeePerGas
          : maxPriorityFeePerGas // ignore: cast_nullable_to_non_nullable
              as String?,
      feeRate: freezed == feeRate
          ? _value.feeRate
          : feeRate // ignore: cast_nullable_to_non_nullable
              as String?,
      waitTime: freezed == waitTime
          ? _value.waitTime
          : waitTime // ignore: cast_nullable_to_non_nullable
              as Duration?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NetworkFeeImpl implements _NetworkFee {
  const _$NetworkFeeImpl(
      {@NumberToStringConverter() this.maxFeePerGas,
      @NumberToStringConverter() this.maxPriorityFeePerGas,
      @NumberToStringConverter() this.feeRate,
      @DurationConverter() this.waitTime});

  factory _$NetworkFeeImpl.fromJson(Map<String, dynamic> json) =>
      _$$NetworkFeeImplFromJson(json);

  @override
  @NumberToStringConverter()
  final String? maxFeePerGas;
  @override
  @NumberToStringConverter()
  final String? maxPriorityFeePerGas;
  @override
  @NumberToStringConverter()
  final String? feeRate;
  @override
  @DurationConverter()
  final Duration? waitTime;

  @override
  String toString() {
    return 'NetworkFee(maxFeePerGas: $maxFeePerGas, maxPriorityFeePerGas: $maxPriorityFeePerGas, feeRate: $feeRate, waitTime: $waitTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkFeeImpl &&
            (identical(other.maxFeePerGas, maxFeePerGas) ||
                other.maxFeePerGas == maxFeePerGas) &&
            (identical(other.maxPriorityFeePerGas, maxPriorityFeePerGas) ||
                other.maxPriorityFeePerGas == maxPriorityFeePerGas) &&
            (identical(other.feeRate, feeRate) || other.feeRate == feeRate) &&
            (identical(other.waitTime, waitTime) ||
                other.waitTime == waitTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, maxFeePerGas, maxPriorityFeePerGas, feeRate, waitTime);

  /// Create a copy of NetworkFee
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkFeeImplCopyWith<_$NetworkFeeImpl> get copyWith =>
      __$$NetworkFeeImplCopyWithImpl<_$NetworkFeeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NetworkFeeImplToJson(
      this,
    );
  }
}

abstract class _NetworkFee implements NetworkFee {
  const factory _NetworkFee(
      {@NumberToStringConverter() final String? maxFeePerGas,
      @NumberToStringConverter() final String? maxPriorityFeePerGas,
      @NumberToStringConverter() final String? feeRate,
      @DurationConverter() final Duration? waitTime}) = _$NetworkFeeImpl;

  factory _NetworkFee.fromJson(Map<String, dynamic> json) =
      _$NetworkFeeImpl.fromJson;

  @override
  @NumberToStringConverter()
  String? get maxFeePerGas;
  @override
  @NumberToStringConverter()
  String? get maxPriorityFeePerGas;
  @override
  @NumberToStringConverter()
  String? get feeRate;
  @override
  @DurationConverter()
  Duration? get waitTime;

  /// Create a copy of NetworkFee
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetworkFeeImplCopyWith<_$NetworkFeeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

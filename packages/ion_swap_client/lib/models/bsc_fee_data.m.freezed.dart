// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bsc_fee_data.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BscFeeData _$BscFeeDataFromJson(Map<String, dynamic> json) {
  return _BscFeeData.fromJson(json);
}

/// @nodoc
mixin _$BscFeeData {
  BigInt get maxFeePerGas => throw _privateConstructorUsedError;
  BigInt get maxPriorityFeePerGas => throw _privateConstructorUsedError;

  /// Serializes this BscFeeData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BscFeeData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BscFeeDataCopyWith<BscFeeData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BscFeeDataCopyWith<$Res> {
  factory $BscFeeDataCopyWith(
          BscFeeData value, $Res Function(BscFeeData) then) =
      _$BscFeeDataCopyWithImpl<$Res, BscFeeData>;
  @useResult
  $Res call({BigInt maxFeePerGas, BigInt maxPriorityFeePerGas});
}

/// @nodoc
class _$BscFeeDataCopyWithImpl<$Res, $Val extends BscFeeData>
    implements $BscFeeDataCopyWith<$Res> {
  _$BscFeeDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BscFeeData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxFeePerGas = null,
    Object? maxPriorityFeePerGas = null,
  }) {
    return _then(_value.copyWith(
      maxFeePerGas: null == maxFeePerGas
          ? _value.maxFeePerGas
          : maxFeePerGas // ignore: cast_nullable_to_non_nullable
              as BigInt,
      maxPriorityFeePerGas: null == maxPriorityFeePerGas
          ? _value.maxPriorityFeePerGas
          : maxPriorityFeePerGas // ignore: cast_nullable_to_non_nullable
              as BigInt,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BscFeeDataImplCopyWith<$Res>
    implements $BscFeeDataCopyWith<$Res> {
  factory _$$BscFeeDataImplCopyWith(
          _$BscFeeDataImpl value, $Res Function(_$BscFeeDataImpl) then) =
      __$$BscFeeDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({BigInt maxFeePerGas, BigInt maxPriorityFeePerGas});
}

/// @nodoc
class __$$BscFeeDataImplCopyWithImpl<$Res>
    extends _$BscFeeDataCopyWithImpl<$Res, _$BscFeeDataImpl>
    implements _$$BscFeeDataImplCopyWith<$Res> {
  __$$BscFeeDataImplCopyWithImpl(
      _$BscFeeDataImpl _value, $Res Function(_$BscFeeDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of BscFeeData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxFeePerGas = null,
    Object? maxPriorityFeePerGas = null,
  }) {
    return _then(_$BscFeeDataImpl(
      maxFeePerGas: null == maxFeePerGas
          ? _value.maxFeePerGas
          : maxFeePerGas // ignore: cast_nullable_to_non_nullable
              as BigInt,
      maxPriorityFeePerGas: null == maxPriorityFeePerGas
          ? _value.maxPriorityFeePerGas
          : maxPriorityFeePerGas // ignore: cast_nullable_to_non_nullable
              as BigInt,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BscFeeDataImpl implements _BscFeeData {
  _$BscFeeDataImpl(
      {required this.maxFeePerGas, required this.maxPriorityFeePerGas});

  factory _$BscFeeDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$BscFeeDataImplFromJson(json);

  @override
  final BigInt maxFeePerGas;
  @override
  final BigInt maxPriorityFeePerGas;

  @override
  String toString() {
    return 'BscFeeData(maxFeePerGas: $maxFeePerGas, maxPriorityFeePerGas: $maxPriorityFeePerGas)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BscFeeDataImpl &&
            (identical(other.maxFeePerGas, maxFeePerGas) ||
                other.maxFeePerGas == maxFeePerGas) &&
            (identical(other.maxPriorityFeePerGas, maxPriorityFeePerGas) ||
                other.maxPriorityFeePerGas == maxPriorityFeePerGas));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, maxFeePerGas, maxPriorityFeePerGas);

  /// Create a copy of BscFeeData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BscFeeDataImplCopyWith<_$BscFeeDataImpl> get copyWith =>
      __$$BscFeeDataImplCopyWithImpl<_$BscFeeDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BscFeeDataImplToJson(
      this,
    );
  }
}

abstract class _BscFeeData implements BscFeeData {
  factory _BscFeeData(
      {required final BigInt maxFeePerGas,
      required final BigInt maxPriorityFeePerGas}) = _$BscFeeDataImpl;

  factory _BscFeeData.fromJson(Map<String, dynamic> json) =
      _$BscFeeDataImpl.fromJson;

  @override
  BigInt get maxFeePerGas;
  @override
  BigInt get maxPriorityFeePerGas;

  /// Create a copy of BscFeeData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BscFeeDataImplCopyWith<_$BscFeeDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

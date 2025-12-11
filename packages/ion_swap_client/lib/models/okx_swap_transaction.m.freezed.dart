// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'okx_swap_transaction.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OkxSwapTransaction _$OkxSwapTransactionFromJson(Map<String, dynamic> json) {
  return _OkxSwapTransaction.fromJson(json);
}

/// @nodoc
mixin _$OkxSwapTransaction {
  String get data => throw _privateConstructorUsedError;
  String get from => throw _privateConstructorUsedError;
  String get to => throw _privateConstructorUsedError;
  String get gas => throw _privateConstructorUsedError;
  String get gasPrice => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;
  String? get maxPriorityFeePerGas => throw _privateConstructorUsedError;
  String? get minReceiveAmount => throw _privateConstructorUsedError;

  /// Serializes this OkxSwapTransaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OkxSwapTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OkxSwapTransactionCopyWith<OkxSwapTransaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OkxSwapTransactionCopyWith<$Res> {
  factory $OkxSwapTransactionCopyWith(
          OkxSwapTransaction value, $Res Function(OkxSwapTransaction) then) =
      _$OkxSwapTransactionCopyWithImpl<$Res, OkxSwapTransaction>;
  @useResult
  $Res call(
      {String data,
      String from,
      String to,
      String gas,
      String gasPrice,
      String value,
      String? maxPriorityFeePerGas,
      String? minReceiveAmount});
}

/// @nodoc
class _$OkxSwapTransactionCopyWithImpl<$Res, $Val extends OkxSwapTransaction>
    implements $OkxSwapTransactionCopyWith<$Res> {
  _$OkxSwapTransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OkxSwapTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? from = null,
    Object? to = null,
    Object? gas = null,
    Object? gasPrice = null,
    Object? value = null,
    Object? maxPriorityFeePerGas = freezed,
    Object? minReceiveAmount = freezed,
  }) {
    return _then(_value.copyWith(
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as String,
      from: null == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      gas: null == gas
          ? _value.gas
          : gas // ignore: cast_nullable_to_non_nullable
              as String,
      gasPrice: null == gasPrice
          ? _value.gasPrice
          : gasPrice // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      maxPriorityFeePerGas: freezed == maxPriorityFeePerGas
          ? _value.maxPriorityFeePerGas
          : maxPriorityFeePerGas // ignore: cast_nullable_to_non_nullable
              as String?,
      minReceiveAmount: freezed == minReceiveAmount
          ? _value.minReceiveAmount
          : minReceiveAmount // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OkxSwapTransactionImplCopyWith<$Res>
    implements $OkxSwapTransactionCopyWith<$Res> {
  factory _$$OkxSwapTransactionImplCopyWith(_$OkxSwapTransactionImpl value,
          $Res Function(_$OkxSwapTransactionImpl) then) =
      __$$OkxSwapTransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String data,
      String from,
      String to,
      String gas,
      String gasPrice,
      String value,
      String? maxPriorityFeePerGas,
      String? minReceiveAmount});
}

/// @nodoc
class __$$OkxSwapTransactionImplCopyWithImpl<$Res>
    extends _$OkxSwapTransactionCopyWithImpl<$Res, _$OkxSwapTransactionImpl>
    implements _$$OkxSwapTransactionImplCopyWith<$Res> {
  __$$OkxSwapTransactionImplCopyWithImpl(_$OkxSwapTransactionImpl _value,
      $Res Function(_$OkxSwapTransactionImpl) _then)
      : super(_value, _then);

  /// Create a copy of OkxSwapTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? from = null,
    Object? to = null,
    Object? gas = null,
    Object? gasPrice = null,
    Object? value = null,
    Object? maxPriorityFeePerGas = freezed,
    Object? minReceiveAmount = freezed,
  }) {
    return _then(_$OkxSwapTransactionImpl(
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as String,
      from: null == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as String,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as String,
      gas: null == gas
          ? _value.gas
          : gas // ignore: cast_nullable_to_non_nullable
              as String,
      gasPrice: null == gasPrice
          ? _value.gasPrice
          : gasPrice // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      maxPriorityFeePerGas: freezed == maxPriorityFeePerGas
          ? _value.maxPriorityFeePerGas
          : maxPriorityFeePerGas // ignore: cast_nullable_to_non_nullable
              as String?,
      minReceiveAmount: freezed == minReceiveAmount
          ? _value.minReceiveAmount
          : minReceiveAmount // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OkxSwapTransactionImpl implements _OkxSwapTransaction {
  _$OkxSwapTransactionImpl(
      {required this.data,
      required this.from,
      required this.to,
      required this.gas,
      required this.gasPrice,
      required this.value,
      this.maxPriorityFeePerGas,
      this.minReceiveAmount});

  factory _$OkxSwapTransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$OkxSwapTransactionImplFromJson(json);

  @override
  final String data;
  @override
  final String from;
  @override
  final String to;
  @override
  final String gas;
  @override
  final String gasPrice;
  @override
  final String value;
  @override
  final String? maxPriorityFeePerGas;
  @override
  final String? minReceiveAmount;

  @override
  String toString() {
    return 'OkxSwapTransaction(data: $data, from: $from, to: $to, gas: $gas, gasPrice: $gasPrice, value: $value, maxPriorityFeePerGas: $maxPriorityFeePerGas, minReceiveAmount: $minReceiveAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OkxSwapTransactionImpl &&
            (identical(other.data, data) || other.data == data) &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.gas, gas) || other.gas == gas) &&
            (identical(other.gasPrice, gasPrice) ||
                other.gasPrice == gasPrice) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.maxPriorityFeePerGas, maxPriorityFeePerGas) ||
                other.maxPriorityFeePerGas == maxPriorityFeePerGas) &&
            (identical(other.minReceiveAmount, minReceiveAmount) ||
                other.minReceiveAmount == minReceiveAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, data, from, to, gas, gasPrice,
      value, maxPriorityFeePerGas, minReceiveAmount);

  /// Create a copy of OkxSwapTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OkxSwapTransactionImplCopyWith<_$OkxSwapTransactionImpl> get copyWith =>
      __$$OkxSwapTransactionImplCopyWithImpl<_$OkxSwapTransactionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OkxSwapTransactionImplToJson(
      this,
    );
  }
}

abstract class _OkxSwapTransaction implements OkxSwapTransaction {
  factory _OkxSwapTransaction(
      {required final String data,
      required final String from,
      required final String to,
      required final String gas,
      required final String gasPrice,
      required final String value,
      final String? maxPriorityFeePerGas,
      final String? minReceiveAmount}) = _$OkxSwapTransactionImpl;

  factory _OkxSwapTransaction.fromJson(Map<String, dynamic> json) =
      _$OkxSwapTransactionImpl.fromJson;

  @override
  String get data;
  @override
  String get from;
  @override
  String get to;
  @override
  String get gas;
  @override
  String get gasPrice;
  @override
  String get value;
  @override
  String? get maxPriorityFeePerGas;
  @override
  String? get minReceiveAmount;

  /// Create a copy of OkxSwapTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OkxSwapTransactionImplCopyWith<_$OkxSwapTransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

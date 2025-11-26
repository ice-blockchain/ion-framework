// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lets_exchange_transaction.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LetsExchangeTransaction _$LetsExchangeTransactionFromJson(Map<String, dynamic> json) {
  return _LetsExchangeTransaction.fromJson(json);
}

/// @nodoc
mixin _$LetsExchangeTransaction {
  @JsonKey(name: 'transaction_id')
  String get transactionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'deposit_amount')
  String get depositAmount => throw _privateConstructorUsedError;
  String get deposit => throw _privateConstructorUsedError;

  /// Serializes this LetsExchangeTransaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LetsExchangeTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LetsExchangeTransactionCopyWith<LetsExchangeTransaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LetsExchangeTransactionCopyWith<$Res> {
  factory $LetsExchangeTransactionCopyWith(
          LetsExchangeTransaction value, $Res Function(LetsExchangeTransaction) then) =
      _$LetsExchangeTransactionCopyWithImpl<$Res, LetsExchangeTransaction>;
  @useResult
  $Res call(
      {@JsonKey(name: 'transaction_id') String transactionId,
      @JsonKey(name: 'deposit_amount') String depositAmount,
      String deposit});
}

/// @nodoc
class _$LetsExchangeTransactionCopyWithImpl<$Res, $Val extends LetsExchangeTransaction>
    implements $LetsExchangeTransactionCopyWith<$Res> {
  _$LetsExchangeTransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LetsExchangeTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transactionId = null,
    Object? depositAmount = null,
    Object? deposit = null,
  }) {
    return _then(_value.copyWith(
      transactionId: null == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String,
      depositAmount: null == depositAmount
          ? _value.depositAmount
          : depositAmount // ignore: cast_nullable_to_non_nullable
              as String,
      deposit: null == deposit
          ? _value.deposit
          : deposit // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LetsExchangeTransactionImplCopyWith<$Res>
    implements $LetsExchangeTransactionCopyWith<$Res> {
  factory _$$LetsExchangeTransactionImplCopyWith(
          _$LetsExchangeTransactionImpl value, $Res Function(_$LetsExchangeTransactionImpl) then) =
      __$$LetsExchangeTransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'transaction_id') String transactionId,
      @JsonKey(name: 'deposit_amount') String depositAmount,
      String deposit});
}

/// @nodoc
class __$$LetsExchangeTransactionImplCopyWithImpl<$Res>
    extends _$LetsExchangeTransactionCopyWithImpl<$Res, _$LetsExchangeTransactionImpl>
    implements _$$LetsExchangeTransactionImplCopyWith<$Res> {
  __$$LetsExchangeTransactionImplCopyWithImpl(
      _$LetsExchangeTransactionImpl _value, $Res Function(_$LetsExchangeTransactionImpl) _then)
      : super(_value, _then);

  /// Create a copy of LetsExchangeTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transactionId = null,
    Object? depositAmount = null,
    Object? deposit = null,
  }) {
    return _then(_$LetsExchangeTransactionImpl(
      transactionId: null == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String,
      depositAmount: null == depositAmount
          ? _value.depositAmount
          : depositAmount // ignore: cast_nullable_to_non_nullable
              as String,
      deposit: null == deposit
          ? _value.deposit
          : deposit // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LetsExchangeTransactionImpl implements _LetsExchangeTransaction {
  _$LetsExchangeTransactionImpl(
      {@JsonKey(name: 'transaction_id') required this.transactionId,
      @JsonKey(name: 'deposit_amount') required this.depositAmount,
      required this.deposit});

  factory _$LetsExchangeTransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$LetsExchangeTransactionImplFromJson(json);

  @override
  @JsonKey(name: 'transaction_id')
  final String transactionId;
  @override
  @JsonKey(name: 'deposit_amount')
  final String depositAmount;
  @override
  final String deposit;

  @override
  String toString() {
    return 'LetsExchangeTransaction(transactionId: $transactionId, depositAmount: $depositAmount, deposit: $deposit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LetsExchangeTransactionImpl &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            (identical(other.depositAmount, depositAmount) ||
                other.depositAmount == depositAmount) &&
            (identical(other.deposit, deposit) || other.deposit == deposit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, transactionId, depositAmount, deposit);

  /// Create a copy of LetsExchangeTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LetsExchangeTransactionImplCopyWith<_$LetsExchangeTransactionImpl> get copyWith =>
      __$$LetsExchangeTransactionImplCopyWithImpl<_$LetsExchangeTransactionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LetsExchangeTransactionImplToJson(
      this,
    );
  }
}

abstract class _LetsExchangeTransaction implements LetsExchangeTransaction {
  factory _LetsExchangeTransaction(
      {@JsonKey(name: 'transaction_id') required final String transactionId,
      @JsonKey(name: 'deposit_amount') required final String depositAmount,
      required final String deposit}) = _$LetsExchangeTransactionImpl;

  factory _LetsExchangeTransaction.fromJson(Map<String, dynamic> json) =
      _$LetsExchangeTransactionImpl.fromJson;

  @override
  @JsonKey(name: 'transaction_id')
  String get transactionId;
  @override
  @JsonKey(name: 'deposit_amount')
  String get depositAmount;
  @override
  String get deposit;

  /// Create a copy of LetsExchangeTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LetsExchangeTransactionImplCopyWith<_$LetsExchangeTransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

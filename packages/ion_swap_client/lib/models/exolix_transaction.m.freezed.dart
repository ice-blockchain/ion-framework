// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exolix_transaction.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExolixTransaction _$ExolixTransactionFromJson(Map<String, dynamic> json) {
  return _ExolixTransaction.fromJson(json);
}

/// @nodoc
mixin _$ExolixTransaction {
  String get id => throw _privateConstructorUsedError;
  num get amount => throw _privateConstructorUsedError;
  TransactionStatus get status => throw _privateConstructorUsedError;
  String get depositAddress => throw _privateConstructorUsedError;

  /// Serializes this ExolixTransaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExolixTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExolixTransactionCopyWith<ExolixTransaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExolixTransactionCopyWith<$Res> {
  factory $ExolixTransactionCopyWith(
          ExolixTransaction value, $Res Function(ExolixTransaction) then) =
      _$ExolixTransactionCopyWithImpl<$Res, ExolixTransaction>;
  @useResult
  $Res call(
      {String id, num amount, TransactionStatus status, String depositAddress});
}

/// @nodoc
class _$ExolixTransactionCopyWithImpl<$Res, $Val extends ExolixTransaction>
    implements $ExolixTransactionCopyWith<$Res> {
  _$ExolixTransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExolixTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? amount = null,
    Object? status = null,
    Object? depositAddress = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as num,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TransactionStatus,
      depositAddress: null == depositAddress
          ? _value.depositAddress
          : depositAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExolixTransactionImplCopyWith<$Res>
    implements $ExolixTransactionCopyWith<$Res> {
  factory _$$ExolixTransactionImplCopyWith(_$ExolixTransactionImpl value,
          $Res Function(_$ExolixTransactionImpl) then) =
      __$$ExolixTransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, num amount, TransactionStatus status, String depositAddress});
}

/// @nodoc
class __$$ExolixTransactionImplCopyWithImpl<$Res>
    extends _$ExolixTransactionCopyWithImpl<$Res, _$ExolixTransactionImpl>
    implements _$$ExolixTransactionImplCopyWith<$Res> {
  __$$ExolixTransactionImplCopyWithImpl(_$ExolixTransactionImpl _value,
      $Res Function(_$ExolixTransactionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExolixTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? amount = null,
    Object? status = null,
    Object? depositAddress = null,
  }) {
    return _then(_$ExolixTransactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as num,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TransactionStatus,
      depositAddress: null == depositAddress
          ? _value.depositAddress
          : depositAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExolixTransactionImpl implements _ExolixTransaction {
  _$ExolixTransactionImpl(
      {required this.id,
      required this.amount,
      required this.status,
      required this.depositAddress});

  factory _$ExolixTransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExolixTransactionImplFromJson(json);

  @override
  final String id;
  @override
  final num amount;
  @override
  final TransactionStatus status;
  @override
  final String depositAddress;

  @override
  String toString() {
    return 'ExolixTransaction(id: $id, amount: $amount, status: $status, depositAddress: $depositAddress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExolixTransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.depositAddress, depositAddress) ||
                other.depositAddress == depositAddress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, amount, status, depositAddress);

  /// Create a copy of ExolixTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExolixTransactionImplCopyWith<_$ExolixTransactionImpl> get copyWith =>
      __$$ExolixTransactionImplCopyWithImpl<_$ExolixTransactionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExolixTransactionImplToJson(
      this,
    );
  }
}

abstract class _ExolixTransaction implements ExolixTransaction {
  factory _ExolixTransaction(
      {required final String id,
      required final num amount,
      required final TransactionStatus status,
      required final String depositAddress}) = _$ExolixTransactionImpl;

  factory _ExolixTransaction.fromJson(Map<String, dynamic> json) =
      _$ExolixTransactionImpl.fromJson;

  @override
  String get id;
  @override
  num get amount;
  @override
  TransactionStatus get status;
  @override
  String get depositAddress;

  /// Create a copy of ExolixTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExolixTransactionImplCopyWith<_$ExolixTransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

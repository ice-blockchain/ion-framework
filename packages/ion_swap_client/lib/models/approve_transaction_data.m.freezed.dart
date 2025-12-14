// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'approve_transaction_data.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ApproveTransactionData _$ApproveTransactionDataFromJson(
    Map<String, dynamic> json) {
  return _ApproveTransactionData.fromJson(json);
}

/// @nodoc
mixin _$ApproveTransactionData {
  String get data => throw _privateConstructorUsedError;
  String get dexContractAddress => throw _privateConstructorUsedError;
  String get gasLimit => throw _privateConstructorUsedError;
  String get gasPrice => throw _privateConstructorUsedError;

  /// Serializes this ApproveTransactionData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApproveTransactionData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApproveTransactionDataCopyWith<ApproveTransactionData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApproveTransactionDataCopyWith<$Res> {
  factory $ApproveTransactionDataCopyWith(ApproveTransactionData value,
          $Res Function(ApproveTransactionData) then) =
      _$ApproveTransactionDataCopyWithImpl<$Res, ApproveTransactionData>;
  @useResult
  $Res call(
      {String data,
      String dexContractAddress,
      String gasLimit,
      String gasPrice});
}

/// @nodoc
class _$ApproveTransactionDataCopyWithImpl<$Res,
        $Val extends ApproveTransactionData>
    implements $ApproveTransactionDataCopyWith<$Res> {
  _$ApproveTransactionDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApproveTransactionData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? dexContractAddress = null,
    Object? gasLimit = null,
    Object? gasPrice = null,
  }) {
    return _then(_value.copyWith(
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as String,
      dexContractAddress: null == dexContractAddress
          ? _value.dexContractAddress
          : dexContractAddress // ignore: cast_nullable_to_non_nullable
              as String,
      gasLimit: null == gasLimit
          ? _value.gasLimit
          : gasLimit // ignore: cast_nullable_to_non_nullable
              as String,
      gasPrice: null == gasPrice
          ? _value.gasPrice
          : gasPrice // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApproveTransactionDataImplCopyWith<$Res>
    implements $ApproveTransactionDataCopyWith<$Res> {
  factory _$$ApproveTransactionDataImplCopyWith(
          _$ApproveTransactionDataImpl value,
          $Res Function(_$ApproveTransactionDataImpl) then) =
      __$$ApproveTransactionDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String data,
      String dexContractAddress,
      String gasLimit,
      String gasPrice});
}

/// @nodoc
class __$$ApproveTransactionDataImplCopyWithImpl<$Res>
    extends _$ApproveTransactionDataCopyWithImpl<$Res,
        _$ApproveTransactionDataImpl>
    implements _$$ApproveTransactionDataImplCopyWith<$Res> {
  __$$ApproveTransactionDataImplCopyWithImpl(
      _$ApproveTransactionDataImpl _value,
      $Res Function(_$ApproveTransactionDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApproveTransactionData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? dexContractAddress = null,
    Object? gasLimit = null,
    Object? gasPrice = null,
  }) {
    return _then(_$ApproveTransactionDataImpl(
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as String,
      dexContractAddress: null == dexContractAddress
          ? _value.dexContractAddress
          : dexContractAddress // ignore: cast_nullable_to_non_nullable
              as String,
      gasLimit: null == gasLimit
          ? _value.gasLimit
          : gasLimit // ignore: cast_nullable_to_non_nullable
              as String,
      gasPrice: null == gasPrice
          ? _value.gasPrice
          : gasPrice // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApproveTransactionDataImpl implements _ApproveTransactionData {
  _$ApproveTransactionDataImpl(
      {required this.data,
      required this.dexContractAddress,
      required this.gasLimit,
      required this.gasPrice});

  factory _$ApproveTransactionDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApproveTransactionDataImplFromJson(json);

  @override
  final String data;
  @override
  final String dexContractAddress;
  @override
  final String gasLimit;
  @override
  final String gasPrice;

  @override
  String toString() {
    return 'ApproveTransactionData(data: $data, dexContractAddress: $dexContractAddress, gasLimit: $gasLimit, gasPrice: $gasPrice)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApproveTransactionDataImpl &&
            (identical(other.data, data) || other.data == data) &&
            (identical(other.dexContractAddress, dexContractAddress) ||
                other.dexContractAddress == dexContractAddress) &&
            (identical(other.gasLimit, gasLimit) ||
                other.gasLimit == gasLimit) &&
            (identical(other.gasPrice, gasPrice) ||
                other.gasPrice == gasPrice));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, data, dexContractAddress, gasLimit, gasPrice);

  /// Create a copy of ApproveTransactionData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApproveTransactionDataImplCopyWith<_$ApproveTransactionDataImpl>
      get copyWith => __$$ApproveTransactionDataImplCopyWithImpl<
          _$ApproveTransactionDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApproveTransactionDataImplToJson(
      this,
    );
  }
}

abstract class _ApproveTransactionData implements ApproveTransactionData {
  factory _ApproveTransactionData(
      {required final String data,
      required final String dexContractAddress,
      required final String gasLimit,
      required final String gasPrice}) = _$ApproveTransactionDataImpl;

  factory _ApproveTransactionData.fromJson(Map<String, dynamic> json) =
      _$ApproveTransactionDataImpl.fromJson;

  @override
  String get data;
  @override
  String get dexContractAddress;
  @override
  String get gasLimit;
  @override
  String get gasPrice;

  /// Create a copy of ApproveTransactionData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApproveTransactionDataImplCopyWith<_$ApproveTransactionDataImpl>
      get copyWith => throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swap_coin.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SwapCoin _$SwapCoinFromJson(Map<String, dynamic> json) {
  return _SwapCoin.fromJson(json);
}

/// @nodoc
mixin _$SwapCoin {
  String get contractAddress => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  int get decimal => throw _privateConstructorUsedError;
  SwapNetwork get network => throw _privateConstructorUsedError;

  /// Used for lets exchange. It's extra id used for some coins,
  /// fox example for XPR it's memo
  String get extraId => throw _privateConstructorUsedError;

  /// Serializes this SwapCoin to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SwapCoin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SwapCoinCopyWith<SwapCoin> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwapCoinCopyWith<$Res> {
  factory $SwapCoinCopyWith(SwapCoin value, $Res Function(SwapCoin) then) =
      _$SwapCoinCopyWithImpl<$Res, SwapCoin>;
  @useResult
  $Res call(
      {String contractAddress,
      String code,
      int decimal,
      SwapNetwork network,
      String extraId});

  $SwapNetworkCopyWith<$Res> get network;
}

/// @nodoc
class _$SwapCoinCopyWithImpl<$Res, $Val extends SwapCoin>
    implements $SwapCoinCopyWith<$Res> {
  _$SwapCoinCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SwapCoin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contractAddress = null,
    Object? code = null,
    Object? decimal = null,
    Object? network = null,
    Object? extraId = null,
  }) {
    return _then(_value.copyWith(
      contractAddress: null == contractAddress
          ? _value.contractAddress
          : contractAddress // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      decimal: null == decimal
          ? _value.decimal
          : decimal // ignore: cast_nullable_to_non_nullable
              as int,
      network: null == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as SwapNetwork,
      extraId: null == extraId
          ? _value.extraId
          : extraId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of SwapCoin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SwapNetworkCopyWith<$Res> get network {
    return $SwapNetworkCopyWith<$Res>(_value.network, (value) {
      return _then(_value.copyWith(network: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SwapCoinImplCopyWith<$Res>
    implements $SwapCoinCopyWith<$Res> {
  factory _$$SwapCoinImplCopyWith(
          _$SwapCoinImpl value, $Res Function(_$SwapCoinImpl) then) =
      __$$SwapCoinImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String contractAddress,
      String code,
      int decimal,
      SwapNetwork network,
      String extraId});

  @override
  $SwapNetworkCopyWith<$Res> get network;
}

/// @nodoc
class __$$SwapCoinImplCopyWithImpl<$Res>
    extends _$SwapCoinCopyWithImpl<$Res, _$SwapCoinImpl>
    implements _$$SwapCoinImplCopyWith<$Res> {
  __$$SwapCoinImplCopyWithImpl(
      _$SwapCoinImpl _value, $Res Function(_$SwapCoinImpl) _then)
      : super(_value, _then);

  /// Create a copy of SwapCoin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contractAddress = null,
    Object? code = null,
    Object? decimal = null,
    Object? network = null,
    Object? extraId = null,
  }) {
    return _then(_$SwapCoinImpl(
      contractAddress: null == contractAddress
          ? _value.contractAddress
          : contractAddress // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      decimal: null == decimal
          ? _value.decimal
          : decimal // ignore: cast_nullable_to_non_nullable
              as int,
      network: null == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as SwapNetwork,
      extraId: null == extraId
          ? _value.extraId
          : extraId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SwapCoinImpl implements _SwapCoin {
  _$SwapCoinImpl(
      {required this.contractAddress,
      required this.code,
      required this.decimal,
      required this.network,
      required this.extraId});

  factory _$SwapCoinImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwapCoinImplFromJson(json);

  @override
  final String contractAddress;
  @override
  final String code;
  @override
  final int decimal;
  @override
  final SwapNetwork network;

  /// Used for lets exchange. It's extra id used for some coins,
  /// fox example for XPR it's memo
  @override
  final String extraId;

  @override
  String toString() {
    return 'SwapCoin(contractAddress: $contractAddress, code: $code, decimal: $decimal, network: $network, extraId: $extraId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwapCoinImpl &&
            (identical(other.contractAddress, contractAddress) ||
                other.contractAddress == contractAddress) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.decimal, decimal) || other.decimal == decimal) &&
            (identical(other.network, network) || other.network == network) &&
            (identical(other.extraId, extraId) || other.extraId == extraId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, contractAddress, code, decimal, network, extraId);

  /// Create a copy of SwapCoin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SwapCoinImplCopyWith<_$SwapCoinImpl> get copyWith =>
      __$$SwapCoinImplCopyWithImpl<_$SwapCoinImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SwapCoinImplToJson(
      this,
    );
  }
}

abstract class _SwapCoin implements SwapCoin {
  factory _SwapCoin(
      {required final String contractAddress,
      required final String code,
      required final int decimal,
      required final SwapNetwork network,
      required final String extraId}) = _$SwapCoinImpl;

  factory _SwapCoin.fromJson(Map<String, dynamic> json) =
      _$SwapCoinImpl.fromJson;

  @override
  String get contractAddress;
  @override
  String get code;
  @override
  int get decimal;
  @override
  SwapNetwork get network;

  /// Used for lets exchange. It's extra id used for some coins,
  /// fox example for XPR it's memo
  @override
  String get extraId;

  /// Create a copy of SwapCoin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SwapCoinImplCopyWith<_$SwapCoinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

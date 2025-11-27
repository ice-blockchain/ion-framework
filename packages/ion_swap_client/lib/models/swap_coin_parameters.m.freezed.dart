// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swap_coin_parameters.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SwapCoinParameters _$SwapCoinParametersFromJson(Map<String, dynamic> json) {
  return _SwapCoinParameters.fromJson(json);
}

/// @nodoc
mixin _$SwapCoinParameters {
  String get sellNetworkId => throw _privateConstructorUsedError;
  String get buyNetworkId => throw _privateConstructorUsedError;
  String get userSellAddress => throw _privateConstructorUsedError;
  String get userBuyAddress => throw _privateConstructorUsedError;
  String get sellCoinContractAddress => throw _privateConstructorUsedError;
  String get buyCoinContractAddress => throw _privateConstructorUsedError;
  String get sellCoinNetworkName => throw _privateConstructorUsedError;
  String get buyCoinNetworkName => throw _privateConstructorUsedError;
  String get amount => throw _privateConstructorUsedError;
  bool get isBridge => throw _privateConstructorUsedError;
  String get sellCoinCode => throw _privateConstructorUsedError;
  String get buyCoinCode => throw _privateConstructorUsedError;

  /// Used for lets exchange. It's extra id used for some coins,
  /// fox example for XPR it's memo
  String get buyExtraId => throw _privateConstructorUsedError;

  /// Serializes this SwapCoinParameters to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SwapCoinParameters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SwapCoinParametersCopyWith<SwapCoinParameters> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwapCoinParametersCopyWith<$Res> {
  factory $SwapCoinParametersCopyWith(
          SwapCoinParameters value, $Res Function(SwapCoinParameters) then) =
      _$SwapCoinParametersCopyWithImpl<$Res, SwapCoinParameters>;
  @useResult
  $Res call(
      {String sellNetworkId,
      String buyNetworkId,
      String userSellAddress,
      String userBuyAddress,
      String sellCoinContractAddress,
      String buyCoinContractAddress,
      String sellCoinNetworkName,
      String buyCoinNetworkName,
      String amount,
      bool isBridge,
      String sellCoinCode,
      String buyCoinCode,
      String buyExtraId});
}

/// @nodoc
class _$SwapCoinParametersCopyWithImpl<$Res, $Val extends SwapCoinParameters>
    implements $SwapCoinParametersCopyWith<$Res> {
  _$SwapCoinParametersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SwapCoinParameters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sellNetworkId = null,
    Object? buyNetworkId = null,
    Object? userSellAddress = null,
    Object? userBuyAddress = null,
    Object? sellCoinContractAddress = null,
    Object? buyCoinContractAddress = null,
    Object? sellCoinNetworkName = null,
    Object? buyCoinNetworkName = null,
    Object? amount = null,
    Object? isBridge = null,
    Object? sellCoinCode = null,
    Object? buyCoinCode = null,
    Object? buyExtraId = null,
  }) {
    return _then(_value.copyWith(
      sellNetworkId: null == sellNetworkId
          ? _value.sellNetworkId
          : sellNetworkId // ignore: cast_nullable_to_non_nullable
              as String,
      buyNetworkId: null == buyNetworkId
          ? _value.buyNetworkId
          : buyNetworkId // ignore: cast_nullable_to_non_nullable
              as String,
      userSellAddress: null == userSellAddress
          ? _value.userSellAddress
          : userSellAddress // ignore: cast_nullable_to_non_nullable
              as String,
      userBuyAddress: null == userBuyAddress
          ? _value.userBuyAddress
          : userBuyAddress // ignore: cast_nullable_to_non_nullable
              as String,
      sellCoinContractAddress: null == sellCoinContractAddress
          ? _value.sellCoinContractAddress
          : sellCoinContractAddress // ignore: cast_nullable_to_non_nullable
              as String,
      buyCoinContractAddress: null == buyCoinContractAddress
          ? _value.buyCoinContractAddress
          : buyCoinContractAddress // ignore: cast_nullable_to_non_nullable
              as String,
      sellCoinNetworkName: null == sellCoinNetworkName
          ? _value.sellCoinNetworkName
          : sellCoinNetworkName // ignore: cast_nullable_to_non_nullable
              as String,
      buyCoinNetworkName: null == buyCoinNetworkName
          ? _value.buyCoinNetworkName
          : buyCoinNetworkName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      isBridge: null == isBridge
          ? _value.isBridge
          : isBridge // ignore: cast_nullable_to_non_nullable
              as bool,
      sellCoinCode: null == sellCoinCode
          ? _value.sellCoinCode
          : sellCoinCode // ignore: cast_nullable_to_non_nullable
              as String,
      buyCoinCode: null == buyCoinCode
          ? _value.buyCoinCode
          : buyCoinCode // ignore: cast_nullable_to_non_nullable
              as String,
      buyExtraId: null == buyExtraId
          ? _value.buyExtraId
          : buyExtraId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SwapCoinParametersImplCopyWith<$Res>
    implements $SwapCoinParametersCopyWith<$Res> {
  factory _$$SwapCoinParametersImplCopyWith(
          _$SwapCoinParametersImpl value, $Res Function(_$SwapCoinParametersImpl) then) =
      __$$SwapCoinParametersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String sellNetworkId,
      String buyNetworkId,
      String userSellAddress,
      String userBuyAddress,
      String sellCoinContractAddress,
      String buyCoinContractAddress,
      String sellCoinNetworkName,
      String buyCoinNetworkName,
      String amount,
      bool isBridge,
      String sellCoinCode,
      String buyCoinCode,
      String buyExtraId});
}

/// @nodoc
class __$$SwapCoinParametersImplCopyWithImpl<$Res>
    extends _$SwapCoinParametersCopyWithImpl<$Res, _$SwapCoinParametersImpl>
    implements _$$SwapCoinParametersImplCopyWith<$Res> {
  __$$SwapCoinParametersImplCopyWithImpl(
      _$SwapCoinParametersImpl _value, $Res Function(_$SwapCoinParametersImpl) _then)
      : super(_value, _then);

  /// Create a copy of SwapCoinParameters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sellNetworkId = null,
    Object? buyNetworkId = null,
    Object? userSellAddress = null,
    Object? userBuyAddress = null,
    Object? sellCoinContractAddress = null,
    Object? buyCoinContractAddress = null,
    Object? sellCoinNetworkName = null,
    Object? buyCoinNetworkName = null,
    Object? amount = null,
    Object? isBridge = null,
    Object? sellCoinCode = null,
    Object? buyCoinCode = null,
    Object? buyExtraId = null,
  }) {
    return _then(_$SwapCoinParametersImpl(
      sellNetworkId: null == sellNetworkId
          ? _value.sellNetworkId
          : sellNetworkId // ignore: cast_nullable_to_non_nullable
              as String,
      buyNetworkId: null == buyNetworkId
          ? _value.buyNetworkId
          : buyNetworkId // ignore: cast_nullable_to_non_nullable
              as String,
      userSellAddress: null == userSellAddress
          ? _value.userSellAddress
          : userSellAddress // ignore: cast_nullable_to_non_nullable
              as String,
      userBuyAddress: null == userBuyAddress
          ? _value.userBuyAddress
          : userBuyAddress // ignore: cast_nullable_to_non_nullable
              as String,
      sellCoinContractAddress: null == sellCoinContractAddress
          ? _value.sellCoinContractAddress
          : sellCoinContractAddress // ignore: cast_nullable_to_non_nullable
              as String,
      buyCoinContractAddress: null == buyCoinContractAddress
          ? _value.buyCoinContractAddress
          : buyCoinContractAddress // ignore: cast_nullable_to_non_nullable
              as String,
      sellCoinNetworkName: null == sellCoinNetworkName
          ? _value.sellCoinNetworkName
          : sellCoinNetworkName // ignore: cast_nullable_to_non_nullable
              as String,
      buyCoinNetworkName: null == buyCoinNetworkName
          ? _value.buyCoinNetworkName
          : buyCoinNetworkName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      isBridge: null == isBridge
          ? _value.isBridge
          : isBridge // ignore: cast_nullable_to_non_nullable
              as bool,
      sellCoinCode: null == sellCoinCode
          ? _value.sellCoinCode
          : sellCoinCode // ignore: cast_nullable_to_non_nullable
              as String,
      buyCoinCode: null == buyCoinCode
          ? _value.buyCoinCode
          : buyCoinCode // ignore: cast_nullable_to_non_nullable
              as String,
      buyExtraId: null == buyExtraId
          ? _value.buyExtraId
          : buyExtraId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SwapCoinParametersImpl implements _SwapCoinParameters {
  _$SwapCoinParametersImpl(
      {required this.sellNetworkId,
      required this.buyNetworkId,
      required this.userSellAddress,
      required this.userBuyAddress,
      required this.sellCoinContractAddress,
      required this.buyCoinContractAddress,
      required this.sellCoinNetworkName,
      required this.buyCoinNetworkName,
      required this.amount,
      required this.isBridge,
      required this.sellCoinCode,
      required this.buyCoinCode,
      required this.buyExtraId});

  factory _$SwapCoinParametersImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwapCoinParametersImplFromJson(json);

  @override
  final String sellNetworkId;
  @override
  final String buyNetworkId;
  @override
  final String userSellAddress;
  @override
  final String userBuyAddress;
  @override
  final String sellCoinContractAddress;
  @override
  final String buyCoinContractAddress;
  @override
  final String sellCoinNetworkName;
  @override
  final String buyCoinNetworkName;
  @override
  final String amount;
  @override
  final bool isBridge;
  @override
  final String sellCoinCode;
  @override
  final String buyCoinCode;

  /// Used for lets exchange. It's extra id used for some coins,
  /// fox example for XPR it's memo
  @override
  final String buyExtraId;

  @override
  String toString() {
    return 'SwapCoinParameters(sellNetworkId: $sellNetworkId, buyNetworkId: $buyNetworkId, userSellAddress: $userSellAddress, userBuyAddress: $userBuyAddress, sellCoinContractAddress: $sellCoinContractAddress, buyCoinContractAddress: $buyCoinContractAddress, sellCoinNetworkName: $sellCoinNetworkName, buyCoinNetworkName: $buyCoinNetworkName, amount: $amount, isBridge: $isBridge, sellCoinCode: $sellCoinCode, buyCoinCode: $buyCoinCode, buyExtraId: $buyExtraId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwapCoinParametersImpl &&
            (identical(other.sellNetworkId, sellNetworkId) ||
                other.sellNetworkId == sellNetworkId) &&
            (identical(other.buyNetworkId, buyNetworkId) || other.buyNetworkId == buyNetworkId) &&
            (identical(other.userSellAddress, userSellAddress) ||
                other.userSellAddress == userSellAddress) &&
            (identical(other.userBuyAddress, userBuyAddress) ||
                other.userBuyAddress == userBuyAddress) &&
            (identical(other.sellCoinContractAddress, sellCoinContractAddress) ||
                other.sellCoinContractAddress == sellCoinContractAddress) &&
            (identical(other.buyCoinContractAddress, buyCoinContractAddress) ||
                other.buyCoinContractAddress == buyCoinContractAddress) &&
            (identical(other.sellCoinNetworkName, sellCoinNetworkName) ||
                other.sellCoinNetworkName == sellCoinNetworkName) &&
            (identical(other.buyCoinNetworkName, buyCoinNetworkName) ||
                other.buyCoinNetworkName == buyCoinNetworkName) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.isBridge, isBridge) || other.isBridge == isBridge) &&
            (identical(other.sellCoinCode, sellCoinCode) || other.sellCoinCode == sellCoinCode) &&
            (identical(other.buyCoinCode, buyCoinCode) || other.buyCoinCode == buyCoinCode) &&
            (identical(other.buyExtraId, buyExtraId) || other.buyExtraId == buyExtraId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      sellNetworkId,
      buyNetworkId,
      userSellAddress,
      userBuyAddress,
      sellCoinContractAddress,
      buyCoinContractAddress,
      sellCoinNetworkName,
      buyCoinNetworkName,
      amount,
      isBridge,
      sellCoinCode,
      buyCoinCode,
      buyExtraId);

  /// Create a copy of SwapCoinParameters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SwapCoinParametersImplCopyWith<_$SwapCoinParametersImpl> get copyWith =>
      __$$SwapCoinParametersImplCopyWithImpl<_$SwapCoinParametersImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SwapCoinParametersImplToJson(
      this,
    );
  }
}

abstract class _SwapCoinParameters implements SwapCoinParameters {
  factory _SwapCoinParameters(
      {required final String sellNetworkId,
      required final String buyNetworkId,
      required final String userSellAddress,
      required final String userBuyAddress,
      required final String sellCoinContractAddress,
      required final String buyCoinContractAddress,
      required final String sellCoinNetworkName,
      required final String buyCoinNetworkName,
      required final String amount,
      required final bool isBridge,
      required final String sellCoinCode,
      required final String buyCoinCode,
      required final String buyExtraId}) = _$SwapCoinParametersImpl;

  factory _SwapCoinParameters.fromJson(Map<String, dynamic> json) =
      _$SwapCoinParametersImpl.fromJson;

  @override
  String get sellNetworkId;
  @override
  String get buyNetworkId;
  @override
  String get userSellAddress;
  @override
  String get userBuyAddress;
  @override
  String get sellCoinContractAddress;
  @override
  String get buyCoinContractAddress;
  @override
  String get sellCoinNetworkName;
  @override
  String get buyCoinNetworkName;
  @override
  String get amount;
  @override
  bool get isBridge;
  @override
  String get sellCoinCode;
  @override
  String get buyCoinCode;

  /// Used for lets exchange. It's extra id used for some coins,
  /// fox example for XPR it's memo
  @override
  String get buyExtraId;

  /// Create a copy of SwapCoinParameters
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SwapCoinParametersImplCopyWith<_$SwapCoinParametersImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

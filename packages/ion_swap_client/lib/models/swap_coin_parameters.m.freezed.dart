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
  String? get userSellAddress => throw _privateConstructorUsedError;
  String? get userBuyAddress => throw _privateConstructorUsedError;
  String get amount => throw _privateConstructorUsedError;
  bool get isBridge => throw _privateConstructorUsedError;
  SwapCoin get sellCoin => throw _privateConstructorUsedError;
  SwapCoin get buyCoin => throw _privateConstructorUsedError;

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
      {String? userSellAddress,
      String? userBuyAddress,
      String amount,
      bool isBridge,
      SwapCoin sellCoin,
      SwapCoin buyCoin});

  $SwapCoinCopyWith<$Res> get sellCoin;
  $SwapCoinCopyWith<$Res> get buyCoin;
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
    Object? userSellAddress = freezed,
    Object? userBuyAddress = freezed,
    Object? amount = null,
    Object? isBridge = null,
    Object? sellCoin = null,
    Object? buyCoin = null,
  }) {
    return _then(_value.copyWith(
      userSellAddress: freezed == userSellAddress
          ? _value.userSellAddress
          : userSellAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      userBuyAddress: freezed == userBuyAddress
          ? _value.userBuyAddress
          : userBuyAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      isBridge: null == isBridge
          ? _value.isBridge
          : isBridge // ignore: cast_nullable_to_non_nullable
              as bool,
      sellCoin: null == sellCoin
          ? _value.sellCoin
          : sellCoin // ignore: cast_nullable_to_non_nullable
              as SwapCoin,
      buyCoin: null == buyCoin
          ? _value.buyCoin
          : buyCoin // ignore: cast_nullable_to_non_nullable
              as SwapCoin,
    ) as $Val);
  }

  /// Create a copy of SwapCoinParameters
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SwapCoinCopyWith<$Res> get sellCoin {
    return $SwapCoinCopyWith<$Res>(_value.sellCoin, (value) {
      return _then(_value.copyWith(sellCoin: value) as $Val);
    });
  }

  /// Create a copy of SwapCoinParameters
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SwapCoinCopyWith<$Res> get buyCoin {
    return $SwapCoinCopyWith<$Res>(_value.buyCoin, (value) {
      return _then(_value.copyWith(buyCoin: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SwapCoinParametersImplCopyWith<$Res>
    implements $SwapCoinParametersCopyWith<$Res> {
  factory _$$SwapCoinParametersImplCopyWith(_$SwapCoinParametersImpl value,
          $Res Function(_$SwapCoinParametersImpl) then) =
      __$$SwapCoinParametersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? userSellAddress,
      String? userBuyAddress,
      String amount,
      bool isBridge,
      SwapCoin sellCoin,
      SwapCoin buyCoin});

  @override
  $SwapCoinCopyWith<$Res> get sellCoin;
  @override
  $SwapCoinCopyWith<$Res> get buyCoin;
}

/// @nodoc
class __$$SwapCoinParametersImplCopyWithImpl<$Res>
    extends _$SwapCoinParametersCopyWithImpl<$Res, _$SwapCoinParametersImpl>
    implements _$$SwapCoinParametersImplCopyWith<$Res> {
  __$$SwapCoinParametersImplCopyWithImpl(_$SwapCoinParametersImpl _value,
      $Res Function(_$SwapCoinParametersImpl) _then)
      : super(_value, _then);

  /// Create a copy of SwapCoinParameters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userSellAddress = freezed,
    Object? userBuyAddress = freezed,
    Object? amount = null,
    Object? isBridge = null,
    Object? sellCoin = null,
    Object? buyCoin = null,
  }) {
    return _then(_$SwapCoinParametersImpl(
      userSellAddress: freezed == userSellAddress
          ? _value.userSellAddress
          : userSellAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      userBuyAddress: freezed == userBuyAddress
          ? _value.userBuyAddress
          : userBuyAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      isBridge: null == isBridge
          ? _value.isBridge
          : isBridge // ignore: cast_nullable_to_non_nullable
              as bool,
      sellCoin: null == sellCoin
          ? _value.sellCoin
          : sellCoin // ignore: cast_nullable_to_non_nullable
              as SwapCoin,
      buyCoin: null == buyCoin
          ? _value.buyCoin
          : buyCoin // ignore: cast_nullable_to_non_nullable
              as SwapCoin,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SwapCoinParametersImpl implements _SwapCoinParameters {
  _$SwapCoinParametersImpl(
      {required this.userSellAddress,
      required this.userBuyAddress,
      required this.amount,
      required this.isBridge,
      required this.sellCoin,
      required this.buyCoin});

  factory _$SwapCoinParametersImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwapCoinParametersImplFromJson(json);

  @override
  final String? userSellAddress;
  @override
  final String? userBuyAddress;
  @override
  final String amount;
  @override
  final bool isBridge;
  @override
  final SwapCoin sellCoin;
  @override
  final SwapCoin buyCoin;

  @override
  String toString() {
    return 'SwapCoinParameters(userSellAddress: $userSellAddress, userBuyAddress: $userBuyAddress, amount: $amount, isBridge: $isBridge, sellCoin: $sellCoin, buyCoin: $buyCoin)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwapCoinParametersImpl &&
            (identical(other.userSellAddress, userSellAddress) ||
                other.userSellAddress == userSellAddress) &&
            (identical(other.userBuyAddress, userBuyAddress) ||
                other.userBuyAddress == userBuyAddress) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.isBridge, isBridge) ||
                other.isBridge == isBridge) &&
            (identical(other.sellCoin, sellCoin) ||
                other.sellCoin == sellCoin) &&
            (identical(other.buyCoin, buyCoin) || other.buyCoin == buyCoin));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userSellAddress, userBuyAddress,
      amount, isBridge, sellCoin, buyCoin);
  @override
  @pragma('vm:prefer-inline')
      __$$SwapCoinParametersImplCopyWithImpl<_$SwapCoinParametersImpl>(this, _$identity);

  /// Create a copy of SwapCoinParameters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SwapCoinParametersImplCopyWith<_$SwapCoinParametersImpl> get copyWith =>
      __$$SwapCoinParametersImplCopyWithImpl<_$SwapCoinParametersImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SwapCoinParametersImplToJson(
      this,
    );
  }
}

abstract class _SwapCoinParameters implements SwapCoinParameters {
  factory _SwapCoinParameters(
      {required final String? userSellAddress,
      required final String? userBuyAddress,
      required final String amount,
      required final bool isBridge,
      required final SwapCoin sellCoin,
      required final SwapCoin buyCoin}) = _$SwapCoinParametersImpl;

  factory _SwapCoinParameters.fromJson(Map<String, dynamic> json) =
      _$SwapCoinParametersImpl.fromJson;

  @override
  String? get userSellAddress;
  @override
  String? get userBuyAddress;
  @override
  String get amount;
  @override
  bool get isBridge;
  @override
  SwapCoin get sellCoin;
  @override
  SwapCoin get buyCoin;

  /// Create a copy of SwapCoinParameters
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SwapCoinParametersImplCopyWith<_$SwapCoinParametersImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

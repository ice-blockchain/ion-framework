// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swap_quote_info.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SwapQuoteInfo _$SwapQuoteInfoFromJson(Map<String, dynamic> json) {
  return _SwapQuoteInfo.fromJson(json);
}

/// @nodoc
mixin _$SwapQuoteInfo {
  SwapQuoteInfoType get type => throw _privateConstructorUsedError;
  double get priceForSellTokenInBuyToken => throw _privateConstructorUsedError;
  SwapQuoteInfoSource get source => throw _privateConstructorUsedError;
  int? get swapImpact => throw _privateConstructorUsedError;
  String? get networkFee => throw _privateConstructorUsedError;
  String? get protocolFee => throw _privateConstructorUsedError;
  ExolixRate? get exolixQuote => throw _privateConstructorUsedError;
  LetsExchangeInfo? get letsExchangeQuote => throw _privateConstructorUsedError;
  SwapQuoteData? get okxQuote => throw _privateConstructorUsedError;
  RelayQuote? get relayQuote => throw _privateConstructorUsedError;
  String? get relayDepositAmount => throw _privateConstructorUsedError;

  /// Serializes this SwapQuoteInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SwapQuoteInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SwapQuoteInfoCopyWith<SwapQuoteInfo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwapQuoteInfoCopyWith<$Res> {
  factory $SwapQuoteInfoCopyWith(SwapQuoteInfo value, $Res Function(SwapQuoteInfo) then) =
      _$SwapQuoteInfoCopyWithImpl<$Res, SwapQuoteInfo>;
  @useResult
  $Res call(
      {SwapQuoteInfoType type,
      double priceForSellTokenInBuyToken,
      SwapQuoteInfoSource source,
      int? swapImpact,
      String? networkFee,
      String? protocolFee,
      ExolixRate? exolixQuote,
      LetsExchangeInfo? letsExchangeQuote,
      SwapQuoteData? okxQuote,
      RelayQuote? relayQuote,
      String? relayDepositAmount});

  $ExolixRateCopyWith<$Res>? get exolixQuote;
  $LetsExchangeInfoCopyWith<$Res>? get letsExchangeQuote;
  $SwapQuoteDataCopyWith<$Res>? get okxQuote;
  $RelayQuoteCopyWith<$Res>? get relayQuote;
}

/// @nodoc
class _$SwapQuoteInfoCopyWithImpl<$Res, $Val extends SwapQuoteInfo>
    implements $SwapQuoteInfoCopyWith<$Res> {
  _$SwapQuoteInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SwapQuoteInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? priceForSellTokenInBuyToken = null,
    Object? source = null,
    Object? swapImpact = freezed,
    Object? networkFee = freezed,
    Object? protocolFee = freezed,
    Object? exolixQuote = freezed,
    Object? letsExchangeQuote = freezed,
    Object? okxQuote = freezed,
    Object? relayQuote = freezed,
    Object? relayDepositAmount = freezed,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as SwapQuoteInfoType,
      priceForSellTokenInBuyToken: null == priceForSellTokenInBuyToken
          ? _value.priceForSellTokenInBuyToken
          : priceForSellTokenInBuyToken // ignore: cast_nullable_to_non_nullable
              as double,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as SwapQuoteInfoSource,
      swapImpact: freezed == swapImpact
          ? _value.swapImpact
          : swapImpact // ignore: cast_nullable_to_non_nullable
              as int?,
      networkFee: freezed == networkFee
          ? _value.networkFee
          : networkFee // ignore: cast_nullable_to_non_nullable
              as String?,
      protocolFee: freezed == protocolFee
          ? _value.protocolFee
          : protocolFee // ignore: cast_nullable_to_non_nullable
              as String?,
      exolixQuote: freezed == exolixQuote
          ? _value.exolixQuote
          : exolixQuote // ignore: cast_nullable_to_non_nullable
              as ExolixRate?,
      letsExchangeQuote: freezed == letsExchangeQuote
          ? _value.letsExchangeQuote
          : letsExchangeQuote // ignore: cast_nullable_to_non_nullable
              as LetsExchangeInfo?,
      okxQuote: freezed == okxQuote
          ? _value.okxQuote
          : okxQuote // ignore: cast_nullable_to_non_nullable
              as SwapQuoteData?,
      relayQuote: freezed == relayQuote
          ? _value.relayQuote
          : relayQuote // ignore: cast_nullable_to_non_nullable
              as RelayQuote?,
      relayDepositAmount: freezed == relayDepositAmount
          ? _value.relayDepositAmount
          : relayDepositAmount // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of SwapQuoteInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExolixRateCopyWith<$Res>? get exolixQuote {
    if (_value.exolixQuote == null) {
      return null;
    }

    return $ExolixRateCopyWith<$Res>(_value.exolixQuote!, (value) {
      return _then(_value.copyWith(exolixQuote: value) as $Val);
    });
  }

  /// Create a copy of SwapQuoteInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LetsExchangeInfoCopyWith<$Res>? get letsExchangeQuote {
    if (_value.letsExchangeQuote == null) {
      return null;
    }

    return $LetsExchangeInfoCopyWith<$Res>(_value.letsExchangeQuote!, (value) {
      return _then(_value.copyWith(letsExchangeQuote: value) as $Val);
    });
  }

  /// Create a copy of SwapQuoteInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SwapQuoteDataCopyWith<$Res>? get okxQuote {
    if (_value.okxQuote == null) {
      return null;
    }

    return $SwapQuoteDataCopyWith<$Res>(_value.okxQuote!, (value) {
      return _then(_value.copyWith(okxQuote: value) as $Val);
    });
  }

  /// Create a copy of SwapQuoteInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RelayQuoteCopyWith<$Res>? get relayQuote {
    if (_value.relayQuote == null) {
      return null;
    }

    return $RelayQuoteCopyWith<$Res>(_value.relayQuote!, (value) {
      return _then(_value.copyWith(relayQuote: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SwapQuoteInfoImplCopyWith<$Res> implements $SwapQuoteInfoCopyWith<$Res> {
  factory _$$SwapQuoteInfoImplCopyWith(
          _$SwapQuoteInfoImpl value, $Res Function(_$SwapQuoteInfoImpl) then) =
      __$$SwapQuoteInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {SwapQuoteInfoType type,
      double priceForSellTokenInBuyToken,
      SwapQuoteInfoSource source,
      int? swapImpact,
      String? networkFee,
      String? protocolFee,
      ExolixRate? exolixQuote,
      LetsExchangeInfo? letsExchangeQuote,
      SwapQuoteData? okxQuote,
      RelayQuote? relayQuote,
      String? relayDepositAmount});

  @override
  $ExolixRateCopyWith<$Res>? get exolixQuote;
  @override
  $LetsExchangeInfoCopyWith<$Res>? get letsExchangeQuote;
  @override
  $SwapQuoteDataCopyWith<$Res>? get okxQuote;
  @override
  $RelayQuoteCopyWith<$Res>? get relayQuote;
}

/// @nodoc
class __$$SwapQuoteInfoImplCopyWithImpl<$Res>
    extends _$SwapQuoteInfoCopyWithImpl<$Res, _$SwapQuoteInfoImpl>
    implements _$$SwapQuoteInfoImplCopyWith<$Res> {
  __$$SwapQuoteInfoImplCopyWithImpl(
      _$SwapQuoteInfoImpl _value, $Res Function(_$SwapQuoteInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of SwapQuoteInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? priceForSellTokenInBuyToken = null,
    Object? source = null,
    Object? swapImpact = freezed,
    Object? networkFee = freezed,
    Object? protocolFee = freezed,
    Object? exolixQuote = freezed,
    Object? letsExchangeQuote = freezed,
    Object? okxQuote = freezed,
    Object? relayQuote = freezed,
    Object? relayDepositAmount = freezed,
  }) {
    return _then(_$SwapQuoteInfoImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as SwapQuoteInfoType,
      priceForSellTokenInBuyToken: null == priceForSellTokenInBuyToken
          ? _value.priceForSellTokenInBuyToken
          : priceForSellTokenInBuyToken // ignore: cast_nullable_to_non_nullable
              as double,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as SwapQuoteInfoSource,
      swapImpact: freezed == swapImpact
          ? _value.swapImpact
          : swapImpact // ignore: cast_nullable_to_non_nullable
              as int?,
      networkFee: freezed == networkFee
          ? _value.networkFee
          : networkFee // ignore: cast_nullable_to_non_nullable
              as String?,
      protocolFee: freezed == protocolFee
          ? _value.protocolFee
          : protocolFee // ignore: cast_nullable_to_non_nullable
              as String?,
      exolixQuote: freezed == exolixQuote
          ? _value.exolixQuote
          : exolixQuote // ignore: cast_nullable_to_non_nullable
              as ExolixRate?,
      letsExchangeQuote: freezed == letsExchangeQuote
          ? _value.letsExchangeQuote
          : letsExchangeQuote // ignore: cast_nullable_to_non_nullable
              as LetsExchangeInfo?,
      okxQuote: freezed == okxQuote
          ? _value.okxQuote
          : okxQuote // ignore: cast_nullable_to_non_nullable
              as SwapQuoteData?,
      relayQuote: freezed == relayQuote
          ? _value.relayQuote
          : relayQuote // ignore: cast_nullable_to_non_nullable
              as RelayQuote?,
      relayDepositAmount: freezed == relayDepositAmount
          ? _value.relayDepositAmount
          : relayDepositAmount // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SwapQuoteInfoImpl implements _SwapQuoteInfo {
  _$SwapQuoteInfoImpl(
      {required this.type,
      required this.priceForSellTokenInBuyToken,
      required this.source,
      this.swapImpact,
      this.networkFee,
      this.protocolFee,
      this.exolixQuote,
      this.letsExchangeQuote,
      this.okxQuote,
      this.relayQuote,
      this.relayDepositAmount});

  factory _$SwapQuoteInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwapQuoteInfoImplFromJson(json);

  @override
  final SwapQuoteInfoType type;
  @override
  final double priceForSellTokenInBuyToken;
  @override
  final SwapQuoteInfoSource source;
  @override
  final int? swapImpact;
  @override
  final String? networkFee;
  @override
  final String? protocolFee;
  @override
  final ExolixRate? exolixQuote;
  @override
  final LetsExchangeInfo? letsExchangeQuote;
  @override
  final SwapQuoteData? okxQuote;
  @override
  final RelayQuote? relayQuote;
  @override
  final String? relayDepositAmount;

  @override
  String toString() {
    return 'SwapQuoteInfo(type: $type, priceForSellTokenInBuyToken: $priceForSellTokenInBuyToken, source: $source, swapImpact: $swapImpact, networkFee: $networkFee, protocolFee: $protocolFee, exolixQuote: $exolixQuote, letsExchangeQuote: $letsExchangeQuote, okxQuote: $okxQuote, relayQuote: $relayQuote, relayDepositAmount: $relayDepositAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwapQuoteInfoImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.priceForSellTokenInBuyToken, priceForSellTokenInBuyToken) ||
                other.priceForSellTokenInBuyToken == priceForSellTokenInBuyToken) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.swapImpact, swapImpact) || other.swapImpact == swapImpact) &&
            (identical(other.networkFee, networkFee) || other.networkFee == networkFee) &&
            (identical(other.protocolFee, protocolFee) || other.protocolFee == protocolFee) &&
            (identical(other.slippage, slippage) || other.slippage == slippage) &&
            (identical(other.exolixQuote, exolixQuote) || other.exolixQuote == exolixQuote) &&
            (identical(other.letsExchangeQuote, letsExchangeQuote) ||
                other.letsExchangeQuote == letsExchangeQuote) &&
            (identical(other.okxQuote, okxQuote) || other.okxQuote == okxQuote) &&
            (identical(other.relayQuote, relayQuote) || other.relayQuote == relayQuote) &&
            (identical(other.relayDepositAmount, relayDepositAmount) ||
                other.relayDepositAmount == relayDepositAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      type,
      priceForSellTokenInBuyToken,
      source,
      swapImpact,
      networkFee,
      protocolFee,
      exolixQuote,
      letsExchangeQuote,
      okxQuote,
      relayQuote,
      relayDepositAmount);

  /// Create a copy of SwapQuoteInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SwapQuoteInfoImplCopyWith<_$SwapQuoteInfoImpl> get copyWith =>
      __$$SwapQuoteInfoImplCopyWithImpl<_$SwapQuoteInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SwapQuoteInfoImplToJson(
      this,
    );
  }
}

abstract class _SwapQuoteInfo implements SwapQuoteInfo {
  factory _SwapQuoteInfo(
      {required final SwapQuoteInfoType type,
      required final double priceForSellTokenInBuyToken,
      required final SwapQuoteInfoSource source,
      final int? swapImpact,
      final String? networkFee,
      final String? protocolFee,
      final ExolixRate? exolixQuote,
      final LetsExchangeInfo? letsExchangeQuote,
      final SwapQuoteData? okxQuote,
      final RelayQuote? relayQuote,
      final String? relayDepositAmount}) = _$SwapQuoteInfoImpl;

  factory _SwapQuoteInfo.fromJson(Map<String, dynamic> json) = _$SwapQuoteInfoImpl.fromJson;

  @override
  SwapQuoteInfoType get type;
  @override
  double get priceForSellTokenInBuyToken;
  @override
  SwapQuoteInfoSource get source;
  @override
  int? get swapImpact;
  @override
  String? get networkFee;
  @override
  String? get protocolFee;
  @override
  ExolixRate? get exolixQuote;
  @override
  LetsExchangeInfo? get letsExchangeQuote;
  @override
  SwapQuoteData? get okxQuote;
  @override
  RelayQuote? get relayQuote;
  @override
  String? get relayDepositAmount;

  /// Create a copy of SwapQuoteInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SwapQuoteInfoImplCopyWith<_$SwapQuoteInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

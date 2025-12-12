// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swap_quote_data.m.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SwapQuoteData _$SwapQuoteDataFromJson(Map<String, dynamic> json) {
  return _SwapQuoteData.fromJson(json);
}

/// @nodoc
mixin _$SwapQuoteData {
  String get chainIndex => throw _privateConstructorUsedError;
  String get fromTokenAmount => throw _privateConstructorUsedError;
  String get toTokenAmount => throw _privateConstructorUsedError;
  OkxTokenInfo get fromToken => throw _privateConstructorUsedError;
  OkxTokenInfo get toToken => throw _privateConstructorUsedError;
  @JsonKey(name: 'priceImpactPercent')
  String? get priceImpactPercent => throw _privateConstructorUsedError;
  @JsonKey(name: 'estimateGasFee')
  String? get estimateGasFee => throw _privateConstructorUsedError;
  @JsonKey(name: 'tradeFee')
  String? get tradeFee => throw _privateConstructorUsedError;

  /// Serializes this SwapQuoteData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SwapQuoteData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SwapQuoteDataCopyWith<SwapQuoteData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwapQuoteDataCopyWith<$Res> {
  factory $SwapQuoteDataCopyWith(
          SwapQuoteData value, $Res Function(SwapQuoteData) then) =
      _$SwapQuoteDataCopyWithImpl<$Res, SwapQuoteData>;
  @useResult
  $Res call(
      {String chainIndex,
      String fromTokenAmount,
      String toTokenAmount,
      OkxTokenInfo fromToken,
      OkxTokenInfo toToken,
      @JsonKey(name: 'priceImpactPercent') String? priceImpactPercent,
      @JsonKey(name: 'estimateGasFee') String? estimateGasFee,
      @JsonKey(name: 'tradeFee') String? tradeFee});

  $OkxTokenInfoCopyWith<$Res> get fromToken;
  $OkxTokenInfoCopyWith<$Res> get toToken;
}

/// @nodoc
class _$SwapQuoteDataCopyWithImpl<$Res, $Val extends SwapQuoteData>
    implements $SwapQuoteDataCopyWith<$Res> {
  _$SwapQuoteDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SwapQuoteData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chainIndex = null,
    Object? fromTokenAmount = null,
    Object? toTokenAmount = null,
    Object? fromToken = null,
    Object? toToken = null,
    Object? priceImpactPercent = freezed,
    Object? estimateGasFee = freezed,
    Object? tradeFee = freezed,
  }) {
    return _then(_value.copyWith(
      chainIndex: null == chainIndex
          ? _value.chainIndex
          : chainIndex // ignore: cast_nullable_to_non_nullable
              as String,
      fromTokenAmount: null == fromTokenAmount
          ? _value.fromTokenAmount
          : fromTokenAmount // ignore: cast_nullable_to_non_nullable
              as String,
      toTokenAmount: null == toTokenAmount
          ? _value.toTokenAmount
          : toTokenAmount // ignore: cast_nullable_to_non_nullable
              as String,
      fromToken: null == fromToken
          ? _value.fromToken
          : fromToken // ignore: cast_nullable_to_non_nullable
              as OkxTokenInfo,
      toToken: null == toToken
          ? _value.toToken
          : toToken // ignore: cast_nullable_to_non_nullable
              as OkxTokenInfo,
      priceImpactPercent: freezed == priceImpactPercent
          ? _value.priceImpactPercent
          : priceImpactPercent // ignore: cast_nullable_to_non_nullable
              as String?,
      estimateGasFee: freezed == estimateGasFee
          ? _value.estimateGasFee
          : estimateGasFee // ignore: cast_nullable_to_non_nullable
              as String?,
      tradeFee: freezed == tradeFee
          ? _value.tradeFee
          : tradeFee // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of SwapQuoteData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OkxTokenInfoCopyWith<$Res> get fromToken {
    return $OkxTokenInfoCopyWith<$Res>(_value.fromToken, (value) {
      return _then(_value.copyWith(fromToken: value) as $Val);
    });
  }

  /// Create a copy of SwapQuoteData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OkxTokenInfoCopyWith<$Res> get toToken {
    return $OkxTokenInfoCopyWith<$Res>(_value.toToken, (value) {
      return _then(_value.copyWith(toToken: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SwapQuoteDataImplCopyWith<$Res>
    implements $SwapQuoteDataCopyWith<$Res> {
  factory _$$SwapQuoteDataImplCopyWith(
          _$SwapQuoteDataImpl value, $Res Function(_$SwapQuoteDataImpl) then) =
      __$$SwapQuoteDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String chainIndex,
      String fromTokenAmount,
      String toTokenAmount,
      OkxTokenInfo fromToken,
      OkxTokenInfo toToken,
      @JsonKey(name: 'priceImpactPercent') String? priceImpactPercent,
      @JsonKey(name: 'estimateGasFee') String? estimateGasFee,
      @JsonKey(name: 'tradeFee') String? tradeFee});

  @override
  $OkxTokenInfoCopyWith<$Res> get fromToken;
  @override
  $OkxTokenInfoCopyWith<$Res> get toToken;
}

/// @nodoc
class __$$SwapQuoteDataImplCopyWithImpl<$Res>
    extends _$SwapQuoteDataCopyWithImpl<$Res, _$SwapQuoteDataImpl>
    implements _$$SwapQuoteDataImplCopyWith<$Res> {
  __$$SwapQuoteDataImplCopyWithImpl(
      _$SwapQuoteDataImpl _value, $Res Function(_$SwapQuoteDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of SwapQuoteData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chainIndex = null,
    Object? fromTokenAmount = null,
    Object? toTokenAmount = null,
    Object? fromToken = null,
    Object? toToken = null,
    Object? priceImpactPercent = freezed,
    Object? estimateGasFee = freezed,
    Object? tradeFee = freezed,
  }) {
    return _then(_$SwapQuoteDataImpl(
      chainIndex: null == chainIndex
          ? _value.chainIndex
          : chainIndex // ignore: cast_nullable_to_non_nullable
              as String,
      fromTokenAmount: null == fromTokenAmount
          ? _value.fromTokenAmount
          : fromTokenAmount // ignore: cast_nullable_to_non_nullable
              as String,
      toTokenAmount: null == toTokenAmount
          ? _value.toTokenAmount
          : toTokenAmount // ignore: cast_nullable_to_non_nullable
              as String,
      fromToken: null == fromToken
          ? _value.fromToken
          : fromToken // ignore: cast_nullable_to_non_nullable
              as OkxTokenInfo,
      toToken: null == toToken
          ? _value.toToken
          : toToken // ignore: cast_nullable_to_non_nullable
              as OkxTokenInfo,
      priceImpactPercent: freezed == priceImpactPercent
          ? _value.priceImpactPercent
          : priceImpactPercent // ignore: cast_nullable_to_non_nullable
              as String?,
      estimateGasFee: freezed == estimateGasFee
          ? _value.estimateGasFee
          : estimateGasFee // ignore: cast_nullable_to_non_nullable
              as String?,
      tradeFee: freezed == tradeFee
          ? _value.tradeFee
          : tradeFee // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SwapQuoteDataImpl implements _SwapQuoteData {
  _$SwapQuoteDataImpl(
      {required this.chainIndex,
      required this.fromTokenAmount,
      required this.toTokenAmount,
      required this.fromToken,
      required this.toToken,
      @JsonKey(name: 'priceImpactPercent') this.priceImpactPercent,
      @JsonKey(name: 'estimateGasFee') this.estimateGasFee,
      @JsonKey(name: 'tradeFee') this.tradeFee});

  factory _$SwapQuoteDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwapQuoteDataImplFromJson(json);

  @override
  final String chainIndex;
  @override
  final String fromTokenAmount;
  @override
  final String toTokenAmount;
  @override
  final OkxTokenInfo fromToken;
  @override
  final OkxTokenInfo toToken;
  @override
  @JsonKey(name: 'priceImpactPercent')
  final String? priceImpactPercent;
  @override
  @JsonKey(name: 'estimateGasFee')
  final String? estimateGasFee;
  @override
  @JsonKey(name: 'tradeFee')
  final String? tradeFee;

  @override
  String toString() {
    return 'SwapQuoteData(chainIndex: $chainIndex, fromTokenAmount: $fromTokenAmount, toTokenAmount: $toTokenAmount, fromToken: $fromToken, toToken: $toToken, priceImpactPercent: $priceImpactPercent, estimateGasFee: $estimateGasFee, tradeFee: $tradeFee)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwapQuoteDataImpl &&
            (identical(other.chainIndex, chainIndex) ||
                other.chainIndex == chainIndex) &&
            (identical(other.fromTokenAmount, fromTokenAmount) ||
                other.fromTokenAmount == fromTokenAmount) &&
            (identical(other.toTokenAmount, toTokenAmount) ||
                other.toTokenAmount == toTokenAmount) &&
            (identical(other.fromToken, fromToken) ||
                other.fromToken == fromToken) &&
            (identical(other.toToken, toToken) || other.toToken == toToken) &&
            (identical(other.priceImpactPercent, priceImpactPercent) ||
                other.priceImpactPercent == priceImpactPercent) &&
            (identical(other.estimateGasFee, estimateGasFee) ||
                other.estimateGasFee == estimateGasFee) &&
            (identical(other.tradeFee, tradeFee) ||
                other.tradeFee == tradeFee));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      chainIndex,
      fromTokenAmount,
      toTokenAmount,
      fromToken,
      toToken,
      priceImpactPercent,
      estimateGasFee,
      tradeFee);

  /// Create a copy of SwapQuoteData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SwapQuoteDataImplCopyWith<_$SwapQuoteDataImpl> get copyWith =>
      __$$SwapQuoteDataImplCopyWithImpl<_$SwapQuoteDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SwapQuoteDataImplToJson(
      this,
    );
  }
}

abstract class _SwapQuoteData implements SwapQuoteData {
  factory _SwapQuoteData(
      {required final String chainIndex,
      required final String fromTokenAmount,
      required final String toTokenAmount,
      required final OkxTokenInfo fromToken,
      required final OkxTokenInfo toToken,
      @JsonKey(name: 'priceImpactPercent') final String? priceImpactPercent,
      @JsonKey(name: 'estimateGasFee') final String? estimateGasFee,
      @JsonKey(name: 'tradeFee') final String? tradeFee}) = _$SwapQuoteDataImpl;

  factory _SwapQuoteData.fromJson(Map<String, dynamic> json) =
      _$SwapQuoteDataImpl.fromJson;

  @override
  String get chainIndex;
  @override
  String get fromTokenAmount;
  @override
  String get toTokenAmount;
  @override
  OkxTokenInfo get fromToken;
  @override
  OkxTokenInfo get toToken;
  @override
  @JsonKey(name: 'priceImpactPercent')
  String? get priceImpactPercent;
  @override
  @JsonKey(name: 'estimateGasFee')
  String? get estimateGasFee;
  @override
  @JsonKey(name: 'tradeFee')
  String? get tradeFee;

  /// Create a copy of SwapQuoteData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SwapQuoteDataImplCopyWith<_$SwapQuoteDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

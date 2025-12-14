// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pricing_response.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PricingResponse _$PricingResponseFromJson(Map<String, dynamic> json) {
  return _PricingResponse.fromJson(json);
}

/// @nodoc
mixin _$PricingResponse {
  String get amount => throw _privateConstructorUsedError;
  String get amountBNB => throw _privateConstructorUsedError;
  double get amountUSD => throw _privateConstructorUsedError;
  double? get usdPriceION => throw _privateConstructorUsedError;
  double? get usdPriceBNB => throw _privateConstructorUsedError;

  /// Serializes this PricingResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PricingResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PricingResponseCopyWith<PricingResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PricingResponseCopyWith<$Res> {
  factory $PricingResponseCopyWith(
    PricingResponse value,
    $Res Function(PricingResponse) then,
  ) = _$PricingResponseCopyWithImpl<$Res, PricingResponse>;
  @useResult
  $Res call({
    String amount,
    String amountBNB,
    double amountUSD,
    double? usdPriceION,
    double? usdPriceBNB,
  });
}

/// @nodoc
class _$PricingResponseCopyWithImpl<$Res, $Val extends PricingResponse>
    implements $PricingResponseCopyWith<$Res> {
  _$PricingResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PricingResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amount = null,
    Object? amountBNB = null,
    Object? amountUSD = null,
    Object? usdPriceION = freezed,
    Object? usdPriceBNB = freezed,
  }) {
    return _then(
      _value.copyWith(
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as String,
            amountBNB: null == amountBNB
                ? _value.amountBNB
                : amountBNB // ignore: cast_nullable_to_non_nullable
                      as String,
            amountUSD: null == amountUSD
                ? _value.amountUSD
                : amountUSD // ignore: cast_nullable_to_non_nullable
                      as double,
            usdPriceION: freezed == usdPriceION
                ? _value.usdPriceION
                : usdPriceION // ignore: cast_nullable_to_non_nullable
                      as double?,
            usdPriceBNB: freezed == usdPriceBNB
                ? _value.usdPriceBNB
                : usdPriceBNB // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PricingResponseImplCopyWith<$Res>
    implements $PricingResponseCopyWith<$Res> {
  factory _$$PricingResponseImplCopyWith(
    _$PricingResponseImpl value,
    $Res Function(_$PricingResponseImpl) then,
  ) = __$$PricingResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String amount,
    String amountBNB,
    double amountUSD,
    double? usdPriceION,
    double? usdPriceBNB,
  });
}

/// @nodoc
class __$$PricingResponseImplCopyWithImpl<$Res>
    extends _$PricingResponseCopyWithImpl<$Res, _$PricingResponseImpl>
    implements _$$PricingResponseImplCopyWith<$Res> {
  __$$PricingResponseImplCopyWithImpl(
    _$PricingResponseImpl _value,
    $Res Function(_$PricingResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PricingResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amount = null,
    Object? amountBNB = null,
    Object? amountUSD = null,
    Object? usdPriceION = freezed,
    Object? usdPriceBNB = freezed,
  }) {
    return _then(
      _$PricingResponseImpl(
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as String,
        amountBNB: null == amountBNB
            ? _value.amountBNB
            : amountBNB // ignore: cast_nullable_to_non_nullable
                  as String,
        amountUSD: null == amountUSD
            ? _value.amountUSD
            : amountUSD // ignore: cast_nullable_to_non_nullable
                  as double,
        usdPriceION: freezed == usdPriceION
            ? _value.usdPriceION
            : usdPriceION // ignore: cast_nullable_to_non_nullable
                  as double?,
        usdPriceBNB: freezed == usdPriceBNB
            ? _value.usdPriceBNB
            : usdPriceBNB // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PricingResponseImpl implements _PricingResponse {
  const _$PricingResponseImpl({
    required this.amount,
    required this.amountBNB,
    required this.amountUSD,
    this.usdPriceION,
    this.usdPriceBNB,
  });

  factory _$PricingResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$PricingResponseImplFromJson(json);

  @override
  final String amount;
  @override
  final String amountBNB;
  @override
  final double amountUSD;
  @override
  final double? usdPriceION;
  @override
  final double? usdPriceBNB;

  @override
  String toString() {
    return 'PricingResponse(amount: $amount, amountBNB: $amountBNB, amountUSD: $amountUSD, usdPriceION: $usdPriceION, usdPriceBNB: $usdPriceBNB)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PricingResponseImpl &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.amountBNB, amountBNB) ||
                other.amountBNB == amountBNB) &&
            (identical(other.amountUSD, amountUSD) ||
                other.amountUSD == amountUSD) &&
            (identical(other.usdPriceION, usdPriceION) ||
                other.usdPriceION == usdPriceION) &&
            (identical(other.usdPriceBNB, usdPriceBNB) ||
                other.usdPriceBNB == usdPriceBNB));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    amount,
    amountBNB,
    amountUSD,
    usdPriceION,
    usdPriceBNB,
  );

  /// Create a copy of PricingResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PricingResponseImplCopyWith<_$PricingResponseImpl> get copyWith =>
      __$$PricingResponseImplCopyWithImpl<_$PricingResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PricingResponseImplToJson(this);
  }
}

abstract class _PricingResponse implements PricingResponse {
  const factory _PricingResponse({
    required final String amount,
    required final String amountBNB,
    required final double amountUSD,
    final double? usdPriceION,
    final double? usdPriceBNB,
  }) = _$PricingResponseImpl;

  factory _PricingResponse.fromJson(Map<String, dynamic> json) =
      _$PricingResponseImpl.fromJson;

  @override
  String get amount;
  @override
  String get amountBNB;
  @override
  double get amountUSD;
  @override
  double? get usdPriceION;
  @override
  double? get usdPriceBNB;

  /// Create a copy of PricingResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PricingResponseImplCopyWith<_$PricingResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

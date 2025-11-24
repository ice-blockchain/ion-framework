// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'market_data_patch.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MarketDataPatch _$MarketDataPatchFromJson(Map<String, dynamic> json) {
  return _MarketDataPatch.fromJson(json);
}

/// @nodoc
mixin _$MarketDataPatch {
  double? get marketCap => throw _privateConstructorUsedError;
  double? get volume => throw _privateConstructorUsedError;
  int? get holders => throw _privateConstructorUsedError;
  double? get priceUSD => throw _privateConstructorUsedError;
  PositionPatch? get position => throw _privateConstructorUsedError;

  /// Serializes this MarketDataPatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MarketDataPatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MarketDataPatchCopyWith<MarketDataPatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MarketDataPatchCopyWith<$Res> {
  factory $MarketDataPatchCopyWith(
    MarketDataPatch value,
    $Res Function(MarketDataPatch) then,
  ) = _$MarketDataPatchCopyWithImpl<$Res, MarketDataPatch>;
  @useResult
  $Res call({
    double? marketCap,
    double? volume,
    int? holders,
    double? priceUSD,
    PositionPatch? position,
  });

  $PositionPatchCopyWith<$Res>? get position;
}

/// @nodoc
class _$MarketDataPatchCopyWithImpl<$Res, $Val extends MarketDataPatch>
    implements $MarketDataPatchCopyWith<$Res> {
  _$MarketDataPatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MarketDataPatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? marketCap = freezed,
    Object? volume = freezed,
    Object? holders = freezed,
    Object? priceUSD = freezed,
    Object? position = freezed,
  }) {
    return _then(
      _value.copyWith(
            marketCap: freezed == marketCap
                ? _value.marketCap
                : marketCap // ignore: cast_nullable_to_non_nullable
                      as double?,
            volume: freezed == volume
                ? _value.volume
                : volume // ignore: cast_nullable_to_non_nullable
                      as double?,
            holders: freezed == holders
                ? _value.holders
                : holders // ignore: cast_nullable_to_non_nullable
                      as int?,
            priceUSD: freezed == priceUSD
                ? _value.priceUSD
                : priceUSD // ignore: cast_nullable_to_non_nullable
                      as double?,
            position: freezed == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as PositionPatch?,
          )
          as $Val,
    );
  }

  /// Create a copy of MarketDataPatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PositionPatchCopyWith<$Res>? get position {
    if (_value.position == null) {
      return null;
    }

    return $PositionPatchCopyWith<$Res>(_value.position!, (value) {
      return _then(_value.copyWith(position: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MarketDataPatchImplCopyWith<$Res>
    implements $MarketDataPatchCopyWith<$Res> {
  factory _$$MarketDataPatchImplCopyWith(
    _$MarketDataPatchImpl value,
    $Res Function(_$MarketDataPatchImpl) then,
  ) = __$$MarketDataPatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double? marketCap,
    double? volume,
    int? holders,
    double? priceUSD,
    PositionPatch? position,
  });

  @override
  $PositionPatchCopyWith<$Res>? get position;
}

/// @nodoc
class __$$MarketDataPatchImplCopyWithImpl<$Res>
    extends _$MarketDataPatchCopyWithImpl<$Res, _$MarketDataPatchImpl>
    implements _$$MarketDataPatchImplCopyWith<$Res> {
  __$$MarketDataPatchImplCopyWithImpl(
    _$MarketDataPatchImpl _value,
    $Res Function(_$MarketDataPatchImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MarketDataPatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? marketCap = freezed,
    Object? volume = freezed,
    Object? holders = freezed,
    Object? priceUSD = freezed,
    Object? position = freezed,
  }) {
    return _then(
      _$MarketDataPatchImpl(
        marketCap: freezed == marketCap
            ? _value.marketCap
            : marketCap // ignore: cast_nullable_to_non_nullable
                  as double?,
        volume: freezed == volume
            ? _value.volume
            : volume // ignore: cast_nullable_to_non_nullable
                  as double?,
        holders: freezed == holders
            ? _value.holders
            : holders // ignore: cast_nullable_to_non_nullable
                  as int?,
        priceUSD: freezed == priceUSD
            ? _value.priceUSD
            : priceUSD // ignore: cast_nullable_to_non_nullable
                  as double?,
        position: freezed == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as PositionPatch?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MarketDataPatchImpl extends _MarketDataPatch {
  const _$MarketDataPatchImpl({
    this.marketCap,
    this.volume,
    this.holders,
    this.priceUSD,
    this.position,
  }) : super._();

  factory _$MarketDataPatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$MarketDataPatchImplFromJson(json);

  @override
  final double? marketCap;
  @override
  final double? volume;
  @override
  final int? holders;
  @override
  final double? priceUSD;
  @override
  final PositionPatch? position;

  @override
  String toString() {
    return 'MarketDataPatch(marketCap: $marketCap, volume: $volume, holders: $holders, priceUSD: $priceUSD, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MarketDataPatchImpl &&
            (identical(other.marketCap, marketCap) ||
                other.marketCap == marketCap) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.holders, holders) || other.holders == holders) &&
            (identical(other.priceUSD, priceUSD) ||
                other.priceUSD == priceUSD) &&
            (identical(other.position, position) ||
                other.position == position));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, marketCap, volume, holders, priceUSD, position);

  /// Create a copy of MarketDataPatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MarketDataPatchImplCopyWith<_$MarketDataPatchImpl> get copyWith =>
      __$$MarketDataPatchImplCopyWithImpl<_$MarketDataPatchImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MarketDataPatchImplToJson(this);
  }
}

abstract class _MarketDataPatch extends MarketDataPatch {
  const factory _MarketDataPatch({
    final double? marketCap,
    final double? volume,
    final int? holders,
    final double? priceUSD,
    final PositionPatch? position,
  }) = _$MarketDataPatchImpl;
  const _MarketDataPatch._() : super._();

  factory _MarketDataPatch.fromJson(Map<String, dynamic> json) =
      _$MarketDataPatchImpl.fromJson;

  @override
  double? get marketCap;
  @override
  double? get volume;
  @override
  int? get holders;
  @override
  double? get priceUSD;
  @override
  PositionPatch? get position;

  /// Create a copy of MarketDataPatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MarketDataPatchImplCopyWith<_$MarketDataPatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

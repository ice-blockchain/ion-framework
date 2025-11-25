// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'market_data.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MarketData _$MarketDataFromJson(Map<String, dynamic> json) {
  return _MarketData.fromJson(json);
}

/// @nodoc
mixin _$MarketData {
  double get marketCap => throw _privateConstructorUsedError;
  double get volume => throw _privateConstructorUsedError;
  int get holders => throw _privateConstructorUsedError;
  double get priceUSD => throw _privateConstructorUsedError;
  Position? get position => throw _privateConstructorUsedError;

  /// Serializes this MarketData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MarketData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MarketDataCopyWith<MarketData> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MarketDataCopyWith<$Res> {
  factory $MarketDataCopyWith(MarketData value, $Res Function(MarketData) then) =
      _$MarketDataCopyWithImpl<$Res, MarketData>;
  @useResult
  $Res call({double marketCap, double volume, int holders, double priceUSD, Position? position});

  $PositionCopyWith<$Res>? get position;
}

/// @nodoc
class _$MarketDataCopyWithImpl<$Res, $Val extends MarketData> implements $MarketDataCopyWith<$Res> {
  _$MarketDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MarketData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? marketCap = null,
    Object? volume = null,
    Object? holders = null,
    Object? priceUSD = null,
    Object? position = freezed,
  }) {
    return _then(
      _value.copyWith(
            marketCap: null == marketCap
                ? _value.marketCap
                : marketCap // ignore: cast_nullable_to_non_nullable
                      as double,
            volume: null == volume
                ? _value.volume
                : volume // ignore: cast_nullable_to_non_nullable
                      as double,
            holders: null == holders
                ? _value.holders
                : holders // ignore: cast_nullable_to_non_nullable
                      as int,
            priceUSD: null == priceUSD
                ? _value.priceUSD
                : priceUSD // ignore: cast_nullable_to_non_nullable
                      as double,
            position: freezed == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as Position?,
          )
          as $Val,
    );
  }

  /// Create a copy of MarketData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PositionCopyWith<$Res>? get position {
    if (_value.position == null) {
      return null;
    }

    return $PositionCopyWith<$Res>(_value.position!, (value) {
      return _then(_value.copyWith(position: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MarketDataImplCopyWith<$Res> implements $MarketDataCopyWith<$Res> {
  factory _$$MarketDataImplCopyWith(_$MarketDataImpl value, $Res Function(_$MarketDataImpl) then) =
      __$$MarketDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double marketCap, double volume, int holders, double priceUSD, Position? position});

  @override
  $PositionCopyWith<$Res>? get position;
}

/// @nodoc
class __$$MarketDataImplCopyWithImpl<$Res> extends _$MarketDataCopyWithImpl<$Res, _$MarketDataImpl>
    implements _$$MarketDataImplCopyWith<$Res> {
  __$$MarketDataImplCopyWithImpl(_$MarketDataImpl _value, $Res Function(_$MarketDataImpl) _then)
    : super(_value, _then);

  /// Create a copy of MarketData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? marketCap = null,
    Object? volume = null,
    Object? holders = null,
    Object? priceUSD = null,
    Object? position = freezed,
  }) {
    return _then(
      _$MarketDataImpl(
        marketCap: null == marketCap
            ? _value.marketCap
            : marketCap // ignore: cast_nullable_to_non_nullable
                  as double,
        volume: null == volume
            ? _value.volume
            : volume // ignore: cast_nullable_to_non_nullable
                  as double,
        holders: null == holders
            ? _value.holders
            : holders // ignore: cast_nullable_to_non_nullable
                  as int,
        priceUSD: null == priceUSD
            ? _value.priceUSD
            : priceUSD // ignore: cast_nullable_to_non_nullable
                  as double,
        position: freezed == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Position?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MarketDataImpl implements _MarketData {
  const _$MarketDataImpl({
    required this.marketCap,
    required this.volume,
    required this.holders,
    required this.priceUSD,
    this.position,
  });

  factory _$MarketDataImpl.fromJson(Map<String, dynamic> json) => _$$MarketDataImplFromJson(json);

  @override
  final double marketCap;
  @override
  final double volume;
  @override
  final int holders;
  @override
  final double priceUSD;
  @override
  final Position? position;

  @override
  String toString() {
    return 'MarketData(marketCap: $marketCap, volume: $volume, holders: $holders, priceUSD: $priceUSD, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MarketDataImpl &&
            (identical(other.marketCap, marketCap) || other.marketCap == marketCap) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.holders, holders) || other.holders == holders) &&
            (identical(other.priceUSD, priceUSD) || other.priceUSD == priceUSD) &&
            (identical(other.position, position) || other.position == position));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, marketCap, volume, holders, priceUSD, position);

  /// Create a copy of MarketData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MarketDataImplCopyWith<_$MarketDataImpl> get copyWith =>
      __$$MarketDataImplCopyWithImpl<_$MarketDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MarketDataImplToJson(this);
  }
}

abstract class _MarketData implements MarketData {
  const factory _MarketData({
    required final double marketCap,
    required final double volume,
    required final int holders,
    required final double priceUSD,
    final Position? position,
  }) = _$MarketDataImpl;

  factory _MarketData.fromJson(Map<String, dynamic> json) = _$MarketDataImpl.fromJson;

  @override
  double get marketCap;
  @override
  double get volume;
  @override
  int get holders;
  @override
  double get priceUSD;
  @override
  Position? get position;

  /// Create a copy of MarketData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MarketDataImplCopyWith<_$MarketDataImpl> get copyWith => throw _privateConstructorUsedError;
}

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
}

/// @nodoc
@JsonSerializable()
class _$MarketDataPatchImpl implements _MarketDataPatch {
  const _$MarketDataPatchImpl({
    this.marketCap,
    this.volume,
    this.holders,
    this.priceUSD,
    this.position,
  });

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
            (identical(other.marketCap, marketCap) || other.marketCap == marketCap) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.holders, holders) || other.holders == holders) &&
            (identical(other.priceUSD, priceUSD) || other.priceUSD == priceUSD) &&
            (identical(other.position, position) || other.position == position));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, marketCap, volume, holders, priceUSD, position);

  @override
  Map<String, dynamic> toJson() {
    return _$$MarketDataPatchImplToJson(this);
  }
}

abstract class _MarketDataPatch implements MarketDataPatch {
  const factory _MarketDataPatch({
    final double? marketCap,
    final double? volume,
    final int? holders,
    final double? priceUSD,
    final PositionPatch? position,
  }) = _$MarketDataPatchImpl;

  factory _MarketDataPatch.fromJson(Map<String, dynamic> json) = _$MarketDataPatchImpl.fromJson;

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
}

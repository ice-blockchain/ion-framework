// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trading_stats.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TradingStats _$TradingStatsFromJson(Map<String, dynamic> json) {
  return _TradingStats.fromJson(json);
}

/// @nodoc
mixin _$TradingStats {
  double get volumeUSD => throw _privateConstructorUsedError;
  int get numberOfBuys => throw _privateConstructorUsedError;
  double get buysTotalAmountUSD => throw _privateConstructorUsedError;
  int get numberOfSells => throw _privateConstructorUsedError;
  double get sellsTotalAmountUSD => throw _privateConstructorUsedError;
  double get netBuy => throw _privateConstructorUsedError;
  double get priceDiff => throw _privateConstructorUsedError;

  /// Serializes this TradingStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TradingStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TradingStatsCopyWith<TradingStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TradingStatsCopyWith<$Res> {
  factory $TradingStatsCopyWith(
    TradingStats value,
    $Res Function(TradingStats) then,
  ) = _$TradingStatsCopyWithImpl<$Res, TradingStats>;
  @useResult
  $Res call({
    double volumeUSD,
    int numberOfBuys,
    double buysTotalAmountUSD,
    int numberOfSells,
    double sellsTotalAmountUSD,
    double netBuy,
    double priceDiff,
  });
}

/// @nodoc
class _$TradingStatsCopyWithImpl<$Res, $Val extends TradingStats>
    implements $TradingStatsCopyWith<$Res> {
  _$TradingStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TradingStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? volumeUSD = null,
    Object? numberOfBuys = null,
    Object? buysTotalAmountUSD = null,
    Object? numberOfSells = null,
    Object? sellsTotalAmountUSD = null,
    Object? netBuy = null,
    Object? priceDiff = null,
  }) {
    return _then(
      _value.copyWith(
            volumeUSD: null == volumeUSD
                ? _value.volumeUSD
                : volumeUSD // ignore: cast_nullable_to_non_nullable
                      as double,
            numberOfBuys: null == numberOfBuys
                ? _value.numberOfBuys
                : numberOfBuys // ignore: cast_nullable_to_non_nullable
                      as int,
            buysTotalAmountUSD: null == buysTotalAmountUSD
                ? _value.buysTotalAmountUSD
                : buysTotalAmountUSD // ignore: cast_nullable_to_non_nullable
                      as double,
            numberOfSells: null == numberOfSells
                ? _value.numberOfSells
                : numberOfSells // ignore: cast_nullable_to_non_nullable
                      as int,
            sellsTotalAmountUSD: null == sellsTotalAmountUSD
                ? _value.sellsTotalAmountUSD
                : sellsTotalAmountUSD // ignore: cast_nullable_to_non_nullable
                      as double,
            netBuy: null == netBuy
                ? _value.netBuy
                : netBuy // ignore: cast_nullable_to_non_nullable
                      as double,
            priceDiff: null == priceDiff
                ? _value.priceDiff
                : priceDiff // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TradingStatsImplCopyWith<$Res>
    implements $TradingStatsCopyWith<$Res> {
  factory _$$TradingStatsImplCopyWith(
    _$TradingStatsImpl value,
    $Res Function(_$TradingStatsImpl) then,
  ) = __$$TradingStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double volumeUSD,
    int numberOfBuys,
    double buysTotalAmountUSD,
    int numberOfSells,
    double sellsTotalAmountUSD,
    double netBuy,
    double priceDiff,
  });
}

/// @nodoc
class __$$TradingStatsImplCopyWithImpl<$Res>
    extends _$TradingStatsCopyWithImpl<$Res, _$TradingStatsImpl>
    implements _$$TradingStatsImplCopyWith<$Res> {
  __$$TradingStatsImplCopyWithImpl(
    _$TradingStatsImpl _value,
    $Res Function(_$TradingStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TradingStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? volumeUSD = null,
    Object? numberOfBuys = null,
    Object? buysTotalAmountUSD = null,
    Object? numberOfSells = null,
    Object? sellsTotalAmountUSD = null,
    Object? netBuy = null,
    Object? priceDiff = null,
  }) {
    return _then(
      _$TradingStatsImpl(
        volumeUSD: null == volumeUSD
            ? _value.volumeUSD
            : volumeUSD // ignore: cast_nullable_to_non_nullable
                  as double,
        numberOfBuys: null == numberOfBuys
            ? _value.numberOfBuys
            : numberOfBuys // ignore: cast_nullable_to_non_nullable
                  as int,
        buysTotalAmountUSD: null == buysTotalAmountUSD
            ? _value.buysTotalAmountUSD
            : buysTotalAmountUSD // ignore: cast_nullable_to_non_nullable
                  as double,
        numberOfSells: null == numberOfSells
            ? _value.numberOfSells
            : numberOfSells // ignore: cast_nullable_to_non_nullable
                  as int,
        sellsTotalAmountUSD: null == sellsTotalAmountUSD
            ? _value.sellsTotalAmountUSD
            : sellsTotalAmountUSD // ignore: cast_nullable_to_non_nullable
                  as double,
        netBuy: null == netBuy
            ? _value.netBuy
            : netBuy // ignore: cast_nullable_to_non_nullable
                  as double,
        priceDiff: null == priceDiff
            ? _value.priceDiff
            : priceDiff // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TradingStatsImpl implements _TradingStats {
  const _$TradingStatsImpl({
    required this.volumeUSD,
    required this.numberOfBuys,
    required this.buysTotalAmountUSD,
    required this.numberOfSells,
    required this.sellsTotalAmountUSD,
    required this.netBuy,
    required this.priceDiff,
  });

  factory _$TradingStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$TradingStatsImplFromJson(json);

  @override
  final double volumeUSD;
  @override
  final int numberOfBuys;
  @override
  final double buysTotalAmountUSD;
  @override
  final int numberOfSells;
  @override
  final double sellsTotalAmountUSD;
  @override
  final double netBuy;
  @override
  final double priceDiff;

  @override
  String toString() {
    return 'TradingStats(volumeUSD: $volumeUSD, numberOfBuys: $numberOfBuys, buysTotalAmountUSD: $buysTotalAmountUSD, numberOfSells: $numberOfSells, sellsTotalAmountUSD: $sellsTotalAmountUSD, netBuy: $netBuy, priceDiff: $priceDiff)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TradingStatsImpl &&
            (identical(other.volumeUSD, volumeUSD) ||
                other.volumeUSD == volumeUSD) &&
            (identical(other.numberOfBuys, numberOfBuys) ||
                other.numberOfBuys == numberOfBuys) &&
            (identical(other.buysTotalAmountUSD, buysTotalAmountUSD) ||
                other.buysTotalAmountUSD == buysTotalAmountUSD) &&
            (identical(other.numberOfSells, numberOfSells) ||
                other.numberOfSells == numberOfSells) &&
            (identical(other.sellsTotalAmountUSD, sellsTotalAmountUSD) ||
                other.sellsTotalAmountUSD == sellsTotalAmountUSD) &&
            (identical(other.netBuy, netBuy) || other.netBuy == netBuy) &&
            (identical(other.priceDiff, priceDiff) ||
                other.priceDiff == priceDiff));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    volumeUSD,
    numberOfBuys,
    buysTotalAmountUSD,
    numberOfSells,
    sellsTotalAmountUSD,
    netBuy,
    priceDiff,
  );

  /// Create a copy of TradingStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TradingStatsImplCopyWith<_$TradingStatsImpl> get copyWith =>
      __$$TradingStatsImplCopyWithImpl<_$TradingStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TradingStatsImplToJson(this);
  }
}

abstract class _TradingStats implements TradingStats {
  const factory _TradingStats({
    required final double volumeUSD,
    required final int numberOfBuys,
    required final double buysTotalAmountUSD,
    required final int numberOfSells,
    required final double sellsTotalAmountUSD,
    required final double netBuy,
    required final double priceDiff,
  }) = _$TradingStatsImpl;

  factory _TradingStats.fromJson(Map<String, dynamic> json) =
      _$TradingStatsImpl.fromJson;

  @override
  double get volumeUSD;
  @override
  int get numberOfBuys;
  @override
  double get buysTotalAmountUSD;
  @override
  int get numberOfSells;
  @override
  double get sellsTotalAmountUSD;
  @override
  double get netBuy;
  @override
  double get priceDiff;

  /// Create a copy of TradingStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TradingStatsImplCopyWith<_$TradingStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timeframe_trading_stats.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TimeframeTradingStats {
  Map<Timeframe, TradingStats> get stats => throw _privateConstructorUsedError;

  /// Create a copy of TimeframeTradingStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimeframeTradingStatsCopyWith<TimeframeTradingStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimeframeTradingStatsCopyWith<$Res> {
  factory $TimeframeTradingStatsCopyWith(
    TimeframeTradingStats value,
    $Res Function(TimeframeTradingStats) then,
  ) = _$TimeframeTradingStatsCopyWithImpl<$Res, TimeframeTradingStats>;
  @useResult
  $Res call({Map<Timeframe, TradingStats> stats});
}

/// @nodoc
class _$TimeframeTradingStatsCopyWithImpl<
  $Res,
  $Val extends TimeframeTradingStats
>
    implements $TimeframeTradingStatsCopyWith<$Res> {
  _$TimeframeTradingStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimeframeTradingStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? stats = null}) {
    return _then(
      _value.copyWith(
            stats: null == stats
                ? _value.stats
                : stats // ignore: cast_nullable_to_non_nullable
                      as Map<Timeframe, TradingStats>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TimeframeTradingStatsImplCopyWith<$Res>
    implements $TimeframeTradingStatsCopyWith<$Res> {
  factory _$$TimeframeTradingStatsImplCopyWith(
    _$TimeframeTradingStatsImpl value,
    $Res Function(_$TimeframeTradingStatsImpl) then,
  ) = __$$TimeframeTradingStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<Timeframe, TradingStats> stats});
}

/// @nodoc
class __$$TimeframeTradingStatsImplCopyWithImpl<$Res>
    extends
        _$TimeframeTradingStatsCopyWithImpl<$Res, _$TimeframeTradingStatsImpl>
    implements _$$TimeframeTradingStatsImplCopyWith<$Res> {
  __$$TimeframeTradingStatsImplCopyWithImpl(
    _$TimeframeTradingStatsImpl _value,
    $Res Function(_$TimeframeTradingStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimeframeTradingStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? stats = null}) {
    return _then(
      _$TimeframeTradingStatsImpl(
        stats: null == stats
            ? _value._stats
            : stats // ignore: cast_nullable_to_non_nullable
                  as Map<Timeframe, TradingStats>,
      ),
    );
  }
}

/// @nodoc

class _$TimeframeTradingStatsImpl implements _TimeframeTradingStats {
  const _$TimeframeTradingStatsImpl({
    required final Map<Timeframe, TradingStats> stats,
  }) : _stats = stats;

  final Map<Timeframe, TradingStats> _stats;
  @override
  Map<Timeframe, TradingStats> get stats {
    if (_stats is EqualUnmodifiableMapView) return _stats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_stats);
  }

  @override
  String toString() {
    return 'TimeframeTradingStats(stats: $stats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimeframeTradingStatsImpl &&
            const DeepCollectionEquality().equals(other._stats, _stats));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_stats));

  /// Create a copy of TimeframeTradingStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimeframeTradingStatsImplCopyWith<_$TimeframeTradingStatsImpl>
  get copyWith =>
      __$$TimeframeTradingStatsImplCopyWithImpl<_$TimeframeTradingStatsImpl>(
        this,
        _$identity,
      );
}

abstract class _TimeframeTradingStats implements TimeframeTradingStats {
  const factory _TimeframeTradingStats({
    required final Map<Timeframe, TradingStats> stats,
  }) = _$TimeframeTradingStatsImpl;

  @override
  Map<Timeframe, TradingStats> get stats;

  /// Create a copy of TimeframeTradingStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimeframeTradingStatsImplCopyWith<_$TimeframeTradingStatsImpl>
  get copyWith => throw _privateConstructorUsedError;
}

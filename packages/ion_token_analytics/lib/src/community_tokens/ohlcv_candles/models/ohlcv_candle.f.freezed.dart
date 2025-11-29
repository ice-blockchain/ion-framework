// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ohlcv_candle.f.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OhlcvCandle _$OhlcvCandleFromJson(Map<String, dynamic> json) {
  return _OhlcvCandle.fromJson(json);
}

/// @nodoc
mixin _$OhlcvCandle {
  int get timestamp => throw _privateConstructorUsedError;
  double get open => throw _privateConstructorUsedError;
  double get high => throw _privateConstructorUsedError;
  double get low => throw _privateConstructorUsedError;
  double get close => throw _privateConstructorUsedError;
  double get volume => throw _privateConstructorUsedError;

  /// Serializes this OhlcvCandle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OhlcvCandle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OhlcvCandleCopyWith<OhlcvCandle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OhlcvCandleCopyWith<$Res> {
  factory $OhlcvCandleCopyWith(
    OhlcvCandle value,
    $Res Function(OhlcvCandle) then,
  ) = _$OhlcvCandleCopyWithImpl<$Res, OhlcvCandle>;
  @useResult
  $Res call({
    int timestamp,
    double open,
    double high,
    double low,
    double close,
    double volume,
  });
}

/// @nodoc
class _$OhlcvCandleCopyWithImpl<$Res, $Val extends OhlcvCandle>
    implements $OhlcvCandleCopyWith<$Res> {
  _$OhlcvCandleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OhlcvCandle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? open = null,
    Object? high = null,
    Object? low = null,
    Object? close = null,
    Object? volume = null,
  }) {
    return _then(
      _value.copyWith(
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as int,
            open: null == open
                ? _value.open
                : open // ignore: cast_nullable_to_non_nullable
                      as double,
            high: null == high
                ? _value.high
                : high // ignore: cast_nullable_to_non_nullable
                      as double,
            low: null == low
                ? _value.low
                : low // ignore: cast_nullable_to_non_nullable
                      as double,
            close: null == close
                ? _value.close
                : close // ignore: cast_nullable_to_non_nullable
                      as double,
            volume: null == volume
                ? _value.volume
                : volume // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OhlcvCandleImplCopyWith<$Res>
    implements $OhlcvCandleCopyWith<$Res> {
  factory _$$OhlcvCandleImplCopyWith(
    _$OhlcvCandleImpl value,
    $Res Function(_$OhlcvCandleImpl) then,
  ) = __$$OhlcvCandleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int timestamp,
    double open,
    double high,
    double low,
    double close,
    double volume,
  });
}

/// @nodoc
class __$$OhlcvCandleImplCopyWithImpl<$Res>
    extends _$OhlcvCandleCopyWithImpl<$Res, _$OhlcvCandleImpl>
    implements _$$OhlcvCandleImplCopyWith<$Res> {
  __$$OhlcvCandleImplCopyWithImpl(
    _$OhlcvCandleImpl _value,
    $Res Function(_$OhlcvCandleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OhlcvCandle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? open = null,
    Object? high = null,
    Object? low = null,
    Object? close = null,
    Object? volume = null,
  }) {
    return _then(
      _$OhlcvCandleImpl(
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as int,
        open: null == open
            ? _value.open
            : open // ignore: cast_nullable_to_non_nullable
                  as double,
        high: null == high
            ? _value.high
            : high // ignore: cast_nullable_to_non_nullable
                  as double,
        low: null == low
            ? _value.low
            : low // ignore: cast_nullable_to_non_nullable
                  as double,
        close: null == close
            ? _value.close
            : close // ignore: cast_nullable_to_non_nullable
                  as double,
        volume: null == volume
            ? _value.volume
            : volume // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OhlcvCandleImpl implements _OhlcvCandle {
  const _$OhlcvCandleImpl({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory _$OhlcvCandleImpl.fromJson(Map<String, dynamic> json) =>
      _$$OhlcvCandleImplFromJson(json);

  @override
  final int timestamp;
  @override
  final double open;
  @override
  final double high;
  @override
  final double low;
  @override
  final double close;
  @override
  final double volume;

  @override
  String toString() {
    return 'OhlcvCandle(timestamp: $timestamp, open: $open, high: $high, low: $low, close: $close, volume: $volume)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OhlcvCandleImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.open, open) || other.open == open) &&
            (identical(other.high, high) || other.high == high) &&
            (identical(other.low, low) || other.low == low) &&
            (identical(other.close, close) || other.close == close) &&
            (identical(other.volume, volume) || other.volume == volume));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, timestamp, open, high, low, close, volume);

  /// Create a copy of OhlcvCandle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OhlcvCandleImplCopyWith<_$OhlcvCandleImpl> get copyWith =>
      __$$OhlcvCandleImplCopyWithImpl<_$OhlcvCandleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OhlcvCandleImplToJson(this);
  }
}

abstract class _OhlcvCandle implements OhlcvCandle {
  const factory _OhlcvCandle({
    required final int timestamp,
    required final double open,
    required final double high,
    required final double low,
    required final double close,
    required final double volume,
  }) = _$OhlcvCandleImpl;

  factory _OhlcvCandle.fromJson(Map<String, dynamic> json) =
      _$OhlcvCandleImpl.fromJson;

  @override
  int get timestamp;
  @override
  double get open;
  @override
  double get high;
  @override
  double get low;
  @override
  double get close;
  @override
  double get volume;

  /// Create a copy of OhlcvCandle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OhlcvCandleImplCopyWith<_$OhlcvCandleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ohlcv_candle.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OhlcvCandleImpl _$$OhlcvCandleImplFromJson(Map<String, dynamic> json) => _$OhlcvCandleImpl(
  timestamp: (json['timestamp'] as num).toInt(),
  open: (json['open'] as num).toDouble(),
  high: (json['high'] as num).toDouble(),
  low: (json['low'] as num).toDouble(),
  close: (json['close'] as num).toDouble(),
  volume: (json['volume'] as num).toDouble(),
);

Map<String, dynamic> _$$OhlcvCandleImplToJson(_$OhlcvCandleImpl instance) => <String, dynamic>{
  'timestamp': instance.timestamp,
  'open': instance.open,
  'high': instance.high,
  'low': instance.low,
  'close': instance.close,
  'volume': instance.volume,
};

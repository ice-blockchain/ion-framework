// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ohlcv_candle.f.freezed.dart';
part 'ohlcv_candle.f.g.dart';

@freezed
class OhlcvCandle with _$OhlcvCandle {
  const factory OhlcvCandle({
    required int timestamp,
    required double open,
    required double high,
    required double low,
    required double close,
    required double volume,
  }) = _OhlcvCandle;

  factory OhlcvCandle.fromJson(Map<String, dynamic> json) => _$OhlcvCandleFromJson(json);
}

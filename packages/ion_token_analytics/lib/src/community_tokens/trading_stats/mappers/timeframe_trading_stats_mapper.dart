// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/trading_stats/models/timeframe_trading_stats.f.dart';
import 'package:ion_token_analytics/src/community_tokens/trading_stats/models/trading_stats.f.dart';

class TimeframeTradingStatsMapper {
  static TimeframeTradingStats fromJson(Map<String, dynamic> json) {
    return TimeframeTradingStats(
      stats: json.map((key, value) {
        if (value is! Map<String, dynamic>) {
          throw ArgumentError('Invalid TradingStats payload for $key: $value');
        }

        return MapEntry(
          _mapKeyToTimeframe(key),
          TradingStats.fromJson(Map<String, dynamic>.from(value)),
        );
      }),
    );
  }
}

Timeframe _mapKeyToTimeframe(String key) {
  switch (key) {
    case '5m':
      return Timeframe.m5;
    case '1h':
      return Timeframe.h1;
    case '6h':
      return Timeframe.h6;
    case '24h':
      return Timeframe.h24;
    default:
      throw UnsupportedError('Unknown timeframe key: $key');
  }
}

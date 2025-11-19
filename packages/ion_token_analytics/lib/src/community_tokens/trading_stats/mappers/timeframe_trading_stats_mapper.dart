// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/trading_stats/models/trading_stats.f.dart';

class TimeframeTradingStatsMapper {
  static Map<String, TradingStats> fromJson(Map<String, dynamic> json) {
    return json.map((key, value) {
      if (value is! Map<String, dynamic>) {
        throw ArgumentError('Invalid TradingStats payload for $key: $value');
      }

      return MapEntry(key, TradingStats.fromJson(Map<String, dynamic>.from(value)));
    });
  }
}

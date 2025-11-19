// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/trading_stats/models/trading_stats.f.dart';

part 'timeframe_trading_stats.f.freezed.dart';

enum Timeframe { m5, h1, h6, h24 }

@freezed
class TimeframeTradingStats with _$TimeframeTradingStats {
  const factory TimeframeTradingStats({required Map<Timeframe, TradingStats> stats}) =
      _TimeframeTradingStats;
}

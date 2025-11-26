// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'trading_stats.f.freezed.dart';
part 'trading_stats.f.g.dart';

@freezed
class TradingStats with _$TradingStats {
  const factory TradingStats({
    required double volumeUSD,
    required int numberOfBuys,
    required double buysTotalAmountUSD,
    required int numberOfSells,
    required double sellsTotalAmountUSD,
    required double netBuy,
  }) = _TradingStats;

  factory TradingStats.fromJson(Map<String, dynamic> json) => _$TradingStatsFromJson(json);
}

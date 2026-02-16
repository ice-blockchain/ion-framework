// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:ion/generated/assets.gen.dart';

enum ChartTimeRange { m1, m3, m5, m15, m30, h1, d1 }

enum ChartMetric { close, marketCap }

extension ChartMetricExtension on ChartMetric {
  String get iconAsset => switch (this) {
        ChartMetric.close => Assets.svg.iconTagPriceLinear,
        ChartMetric.marketCap => Assets.svg.iconMemeMarketcap,
      };
}

extension ChartTimeRangeExtension on ChartTimeRange {
  String get label => switch (this) {
        ChartTimeRange.m1 => '1m',
        ChartTimeRange.m3 => '3m',
        ChartTimeRange.m5 => '5m',
        ChartTimeRange.m15 => '15m',
        ChartTimeRange.m30 => '30m',
        ChartTimeRange.h1 => '1h',
        ChartTimeRange.d1 => '1d',
      };

  String get intervalString => switch (this) {
        ChartTimeRange.m1 => '1m',
        ChartTimeRange.m3 => '3m',
        ChartTimeRange.m5 => '5m',
        ChartTimeRange.m15 => '15m',
        ChartTimeRange.m30 => '30m',
        ChartTimeRange.h1 => '1h',
        ChartTimeRange.d1 => '24h',
      };

  Duration get duration => switch (this) {
        ChartTimeRange.m1 => const Duration(minutes: 1),
        ChartTimeRange.m3 => const Duration(minutes: 3),
        ChartTimeRange.m5 => const Duration(minutes: 5),
        ChartTimeRange.m15 => const Duration(minutes: 15),
        ChartTimeRange.m30 => const Duration(minutes: 30),
        ChartTimeRange.h1 => const Duration(hours: 1),
        ChartTimeRange.d1 => const Duration(days: 1),
      };
}

class ChartCandle {
  const ChartCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.marketCap,
    required this.price,
    required this.date,
  });

  final double open;
  final double high;
  final double low;
  final double close;
  final double marketCap;
  final Decimal price;
  final DateTime date;

  double valueFor(ChartMetric metric) => switch (metric) {
        ChartMetric.close => close,
        ChartMetric.marketCap => marketCap,
      };
}

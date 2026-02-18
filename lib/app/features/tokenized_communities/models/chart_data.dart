// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:ion/generated/assets.gen.dart';

enum ChartTimeRange {
  m1('1m', '1m', Duration(minutes: 1)),
  m3('3m', '3m', Duration(minutes: 3)),
  m5('5m', '5m', Duration(minutes: 5)),
  m15('15m', '15m', Duration(minutes: 15)),
  m30('30m', '30m', Duration(minutes: 30)),
  h1('1h', '1h', Duration(hours: 1)),
  d1('1d', '24h', Duration(days: 1)); // Different intervalString here (24h)

  const ChartTimeRange(this.label, this.intervalString, this.duration);

  final String label;
  final String intervalString;
  final Duration duration;
}

enum ChartMetric { close, marketCap }

extension ChartMetricExtension on ChartMetric {
  String get iconAsset => switch (this) {
        ChartMetric.close => Assets.svg.iconTagPriceLinear,
        ChartMetric.marketCap => Assets.svg.iconMemeMarketcap,
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

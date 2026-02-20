// SPDX-License-Identifier: ice License 1.0

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/tokenized_communities/models/chart_data.dart';
import 'package:ion/app/features/tokenized_communities/utils/chart_metric_value_formatter.dart';
import 'package:ion/app/utils/string.dart';

// Calculates the Y-axis reserved width using the wider label across all
// metrics so the chart area stays stable when switching between them.
double useChartReservedSize({
  required List<ChartCandle> candles,
  required TextStyle labelStyle,
}) {
  final last = candles.lastOrNull;

  return useMemoized(
    () {
      var maxClose = 0.0;
      var maxMcap = 0.0;
      for (final c in candles) {
        if (c.close > maxClose) maxClose = c.close;
        if (c.marketCap > maxMcap) maxMcap = c.marketCap;
      }
      return math.max(
        _labelWidth(maxClose, labelStyle),
        _labelWidth(maxMcap, labelStyle),
      );
    },
    // Realtime updates can modify the last candle or append a new one.
    [candles.length, last?.close, last?.marketCap, labelStyle],
  );
}

double _labelWidth(double maxY, TextStyle style) {
  final chartAnnotationPadding = 6.0.s;
  final label = formatChartMetricValue(maxY);
  return calculateTextWidth(label, style) + chartAnnotationPadding;
}

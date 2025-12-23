// SPDX-License-Identifier: ice License 1.0

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/utils/formatters.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chart_calculation_data_provider.r.g.dart';

class ChartCalculationData {
  const ChartCalculationData({
    required this.minY,
    required this.maxY,
    required this.chartMinY,
    required this.chartMaxY,
    required this.spots,
    required this.indexToLabel,
    required this.xAxisStep,
    required this.maxX,
  });

  final double minY;
  final double maxY;
  final double chartMinY;
  final double chartMaxY;
  final List<FlSpot> spots;
  final Map<int, String> indexToLabel;
  final double xAxisStep;
  final double maxX;
}

@riverpod
ChartCalculationData? chartCalculationData(
  Ref ref, {
  required List<ChartCandle> candles,
}) {
  if (candles.isEmpty) {
    return null;
  }

  // Single-pass calculation of min/max
  var minY = candles.first.close;
  var maxY = candles.first.close;

  for (final candle in candles.skip(1)) {
    final close = candle.close;
    if (close < minY) minY = close;
    if (close > maxY) maxY = close;
  }

  // Calculate Y-axis padding
  final yPadding = _calculateYPadding(minY, maxY);
  final chartMinY = minY - yPadding;
  final chartMaxY = maxY + yPadding;

  // Transform candles to FlSpot
  final spots = candles
      .asMap()
      .entries
      .map((entry) => FlSpot(entry.key.toDouble(), entry.value.close))
      .toList();

  // Build bottom labels from candle times (max 8 evenly spaced)
  final desiredBottom = math.min(8, candles.length);
  final indexToLabel = <int, String>{};
  double xAxisStep = 1;
  if (desiredBottom > 0 && candles.length > 1) {
    xAxisStep = (candles.length - 1) / (desiredBottom - 1);
    for (var i = 0; i < desiredBottom; i++) {
      final idx = (i * xAxisStep).round().clamp(0, candles.length - 1);
      indexToLabel[idx] = formatChartTime(candles[idx].date);
    }
  }

  final maxX = (candles.length - 1).toDouble();

  return ChartCalculationData(
    minY: minY,
    maxY: maxY,
    chartMinY: chartMinY,
    chartMaxY: chartMaxY,
    spots: spots,
    indexToLabel: indexToLabel,
    xAxisStep: xAxisStep,
    maxX: maxX,
  );
}

// Calculates Y-axis padding for chart visualization.
// Returns 10% of the range if values differ, or 5% of the minimum value
// (with a minimum of 0.0001) when all values are identical to prevent flat lines.
double _calculateYPadding(double minY, double maxY) {
  final range = maxY - minY;
  if (range > 0) {
    return range * 0.1;
  }
  // Minimum 5% padding when all values are identical
  return (minY * 0.05).clamp(0.0001, double.infinity);
}

// SPDX-License-Identifier: ice License 1.0

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/utils/chart_y_padding.dart';
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
  required ChartTimeRange selectedRange,
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
  final yPadding = calculateChartYPadding(minY, maxY);
  final chartMinY = (minY - yPadding).clamp(0.0, double.infinity);
  final chartMaxY = maxY + yPadding;

  // Transform candles to FlSpot
  final spots = candles
      .asMap()
      .entries
      .map((entry) => FlSpot(entry.key.toDouble(), entry.value.close))
      .toList();

  // Build bottom labels with consistent spacing
  // Calculate labels based on scale: 8 labels per screen (35 candles)
  // When scale = 1.0 (< 35 candles), limit to actual candle count
  // When scale > 1.0, use formula: (totalCandles / 35) * 8
  const maxPointsPerScreen = 35;
  const labelsPerScreen = 8;

  final scale = candles.length < maxPointsPerScreen ? 1.0 : candles.length / maxPointsPerScreen;
  final calculatedLabels = (scale * labelsPerScreen).round();
  final bottomLabelsCount = candles.length <= 1
      ? candles.length
      : scale == 1.0
          ? math.min(candles.length, labelsPerScreen) // Limit to actual candles when scale = 1
          : math.max(1, calculatedLabels); // Use calculated value when scale > 1

  final indexToLabel = <int, String>{};
  double xAxisStep = 1;
  if (bottomLabelsCount > 0 && candles.length > 1) {
    // Map labels proportionally to actual candles
    for (var i = 0; i < bottomLabelsCount; i++) {
      final progress = i / (bottomLabelsCount - 1);
      final idx = (progress * (candles.length - 1)).round().clamp(0, candles.length - 1);
      indexToLabel[idx] = formatChartAxisLabel(candles[idx].date, selectedRange);
    }
    xAxisStep = (candles.length - 1) / (bottomLabelsCount - 1);
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

// SPDX-License-Identifier: ice License 1.0

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/utils/formatters.dart';
import 'package:ion/app/features/communities/views/components/chart_component.dart';

class TokenAreaLineChart extends StatelessWidget {
  const TokenAreaLineChart({
    required this.candles,
    this.isLoading = false,
    super.key,
  });

  final List<ChartCandle> candles;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final styles = context.theme.appTextThemes;

    if (candles.isEmpty) {
      return const SizedBox.shrink();
    }

    final minY = candles.map((c) => c.close).reduce(math.min);
    final maxY = candles.map((c) => c.close).reduce(math.max);

    final yPadding = (maxY - minY) * 0.1;
    final chartMinY = minY - yPadding;
    final chartMaxY = maxY + yPadding;

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

    // In loading state we use a neutral/disabled color instead of blue.
    final lineColor = isLoading ? colors.tertiaryText.withValues(alpha: 0.4) : colors.primaryAccent;

    return ClipRect(
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          minX: 0,
          maxX: (candles.length - 1).toDouble(),
          clipData: const FlClipData.all(), // Clip line to chart bounds
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(
            drawHorizontalLine: false,
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45.0.s,
                getTitlesWidget: (value, meta) => ChartPriceLabel(value: value),
              ),
            ),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26.0.s,
                interval: xAxisStep,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  final text = indexToLabel[i];
                  if (text == null) return const SizedBox.shrink();
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      text,
                      style: styles.caption5.copyWith(color: colors.tertiaryText),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: !isLoading
              ? LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colors.primaryBackground,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots
                          .map(
                            (spot) => LineTooltipItem(
                              spot.y.toStringAsFixed(4),
                              styles.caption2.copyWith(color: colors.primaryText),
                            ),
                          )
                          .toList();
                    },
                  ),
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: colors.primaryAccent.withValues(alpha: 0.3),
                          strokeWidth: 0.5.s,
                        ),
                        const FlDotData(),
                      );
                    }).toList();
                  },
                  getTouchLineStart: (_, __) => 0,
                  getTouchLineEnd: (_, __) => double.infinity,
                )
              // Disable interactions for loading/empty states.
              : const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: lineColor,
              barWidth: 1.5.s,
              dotData: FlDotData(
                checkToShowDot: (spot, barData) => spot.x == barData.spots.last.x,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3.0.s,
                    color: lineColor,
                    strokeWidth: 1.5.s,
                    strokeColor: colors.secondaryBackground,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: 0.3),
                    lineColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

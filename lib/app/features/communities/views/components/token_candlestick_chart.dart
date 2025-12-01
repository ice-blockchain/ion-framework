// SPDX-License-Identifier: ice License 1.0

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/views/components/chart_component.dart';

class TokenCandlestickChart extends StatelessWidget {
  const TokenCandlestickChart({
    required this.candles,
    super.key,
  });

  final List<ChartCandle> candles;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final styles = context.theme.appTextThemes;

    if (candles.isEmpty) {
      return const SizedBox.shrink();
    }

    final minY = candles.map((c) => c.low).reduce(math.min);
    final maxY = candles.map((c) => c.high).reduce(math.max);

    final candlestickSpots = candles
        .asMap()
        .entries
        .mapIndexed(
          (index, entry) => CandlestickSpot(
            x: index.toDouble(),
            open: entry.value.open,
            high: entry.value.high,
            low: entry.value.low,
            close: entry.value.close,
          ),
        )
        .toList();

    // Build bottom labels from candle dates (max 8 evenly spaced)
    final desiredBottom = math.min(8, candles.length);
    final indexToLabel = <int, String>{};
    double xAxisStep = 1;
    if (desiredBottom > 0) {
      xAxisStep = desiredBottom == 1 ? 1.0 : (candles.length - 1) / (desiredBottom - 1);
      for (var i = 0; i < desiredBottom; i++) {
        final idx = (i * xAxisStep).round().clamp(0, candles.length - 1);
        indexToLabel[idx] = _formatDate(candles[idx].date);
      }
    }

    return CandlestickChart(
      CandlestickChartData(
        minY: minY,
        maxY: maxY,
        borderData: FlBorderData(show: false),
        candlestickSpots: candlestickSpots,
        candlestickTouchData: CandlestickTouchData(enabled: false),
        gridData: FlGridData(
          drawHorizontalLine: false,
          verticalInterval: xAxisStep,
          getDrawingVerticalLine: (value) => FlLine(color: colors.onTertiaryFill, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35.0.s,
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
        candlestickPainter: DefaultCandlestickPainter(
          candlestickStyleProvider: (spot, index) {
            final color = spot.isUp ? colors.success : colors.lossRed;

            return CandlestickStyle(
              lineColor: color,
              lineWidth: 1.0.s,
              bodyStrokeColor: color,
              bodyStrokeWidth: 0,
              bodyFillColor: color,
              bodyWidth: 5.0.s,
              bodyRadius: 0,
            );
          },
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  return DateFormat('dd/MM').format(d);
}

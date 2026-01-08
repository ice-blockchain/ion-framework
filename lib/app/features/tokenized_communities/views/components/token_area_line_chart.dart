// SPDX-License-Identifier: ice License 1.0

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/chart_calculation_data_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';
import 'package:ion/app/utils/string.dart';

class TokenAreaLineChart extends HookConsumerWidget {
  const TokenAreaLineChart({
    required this.candles,
    this.isLoading = false,
    super.key,
  });

  final List<ChartCandle> candles;
  final bool isLoading;

  double _calculateReservedSize(double maxY, TextStyle style) {
    const chartAnnotationPadding = 10.0;
    return calculateTextWidth(maxY.toStringAsFixed(4), style) + chartAnnotationPadding.s;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final styles = context.theme.appTextThemes;

    final calcData = ref.watch(
      chartCalculationDataProvider(candles: candles),
    );

    if (calcData == null) {
      return const SizedBox.shrink();
    }

    final yAxisLabelTextStyle = styles.caption5.copyWith(color: colors.tertiaryText);
    final reservedSize = useMemoized(
      () => _calculateReservedSize(calcData.chartMaxY, yAxisLabelTextStyle),
      [calcData.chartMaxY, yAxisLabelTextStyle],
    );

    // UI logic stays here
    final lineColor = isLoading ? colors.tertiaryText.withValues(alpha: 0.4) : colors.primaryAccent;

    return LineChart(
      LineChartData(
        minY: calcData.chartMinY,
        maxY: calcData.chartMaxY,
        minX: 0,
        maxX: calcData.maxX,
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
              minIncluded: false,
              maxIncluded: false,
              showTitles: true,
              reservedSize: reservedSize,
              getTitlesWidget: (value, meta) => Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ChartPriceLabel(value: value),
              ),
            ),
          ),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26.0.s,
              interval: calcData.xAxisStep,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                final text = calcData.indexToLabel[i];
                if (text == null) return const SizedBox.shrink();

                final label = Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    text,
                    style: styles.caption5.copyWith(color: colors.tertiaryText),
                  ),
                );

                if (i == 0) {
                  return Transform.translate(
                    offset: Offset(13.0.s, 0),
                    child: label,
                  );
                }

                return label;
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
            spots: calcData.spots,
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
    );
  }
}

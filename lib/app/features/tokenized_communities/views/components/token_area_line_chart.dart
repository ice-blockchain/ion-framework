// SPDX-License-Identifier: ice License 1.0

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/hooks/use_chart_transformation.dart';
import 'package:ion/app/features/tokenized_communities/hooks/use_chart_visible_y_range.dart';
import 'package:ion/app/features/tokenized_communities/providers/chart_calculation_data_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart_tooltip_listener.dart';
import 'package:ion/app/hooks/use_chart_gradient.dart';
import 'package:ion/app/utils/string.dart';

class TokenAreaLineChart extends HookConsumerWidget {
  const TokenAreaLineChart({
    required this.candles,
    required this.selectedRange,
    this.isLoading = false,
    super.key,
  });

  final List<ChartCandle> candles;
  final ChartTimeRange selectedRange;
  final bool isLoading;

  static const _scrollAnimationDuration = Duration(milliseconds: 250);

  double _calculateReservedSize(double maxY, TextStyle style) {
    const chartAnnotationPadding = 10.0;
    return calculateTextWidth(maxY.toStringAsFixed(4), style) + chartAnnotationPadding.s;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final styles = context.theme.appTextThemes;

    final calcData = ref.watch(
      chartCalculationDataProvider(candles: candles, selectedRange: selectedRange),
    );

    if (calcData == null) {
      return const SizedBox.shrink();
    }

    final yAxisLabelTextStyle = styles.caption5.copyWith(color: colors.tertiaryText);
    final reservedSize = useMemoized(
      () => _calculateReservedSize(calcData.chartMaxY, yAxisLabelTextStyle),
      [calcData.chartMaxY, yAxisLabelTextStyle],
    );

    // Chart transformation (scroll/zoom and initial positioning)
    final transformation = useChartTransformation(
      dataPointCount: candles.length,
      reservedSize: reservedSize,
    );

    // Visible Y range calculation
    final visibleYRangeData = useChartVisibleYRange(
      isLoading: isLoading,
      chartKey: transformation.chartKey,
      transformationController: transformation.transformationController,
      reservedSize: reservedSize,
      calcData: calcData,
      candles: candles,
    );

    final lineColor = isLoading ? colors.tertiaryText.withValues(alpha: 0.4) : colors.primaryAccent;
    final canInteract = !isLoading;

    final displayMinY = visibleYRangeData.visibleYRange.value?.minY ?? calcData.chartMinY;
    final displayMaxY = visibleYRangeData.visibleYRange.value?.maxY ?? calcData.chartMaxY;

    final gradient = useChartGradient(
      chartMaxY: calcData.chartMaxY,
      displayMinY: displayMinY,
      displayMaxY: displayMaxY,
      hasVisibleRange: visibleYRangeData.visibleYRange.value != null,
    );

    // Only animate Y-axis changes triggered by scroll, not by data load
    final duration =
        visibleYRangeData.isScrollTriggered.value ? _scrollAnimationDuration : Duration.zero;

    // Hide chart until initial scroll position is set (prevents visible jump)
    return Opacity(
      opacity: transformation.isPositioned.value ? 1.0 : 0.0,
      child: ChartTooltipListener(
        canInteract: canInteract,
        builder: ({required tooltipEnabled, required handleChartTouch}) {
          List<LineTooltipItem?> buildTooltipItems(List<LineBarSpot> touchedSpots) {
            if (!tooltipEnabled) {
              return touchedSpots.map((_) => null).toList();
            }
            return touchedSpots
                .map(
                  (spot) => LineTooltipItem(
                    spot.y.toStringAsFixed(4),
                    styles.caption2.copyWith(color: colors.primaryText),
                  ),
                )
                .toList();
          }

          List<TouchedSpotIndicatorData?> buildTouchedSpotIndicators(
            LineChartBarData barData,
            List<int> spotIndexes,
          ) {
            if (!tooltipEnabled) {
              return spotIndexes.map((_) => null).toList();
            }
            return spotIndexes.map((_) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: colors.primaryAccent.withValues(alpha: 0.3),
                  strokeWidth: 0.5.s,
                ),
                const FlDotData(),
              );
            }).toList();
          }

          return LineChart(
            key: transformation.chartKey,
            duration: duration,
            transformationConfig: FlTransformationConfig(
              scaleAxis: FlScaleAxis.horizontal,
              panEnabled: canInteract,
              scaleEnabled: false,
              transformationController: transformation.transformationController,
            ),
            LineChartData(
              minY: displayMinY,
              maxY: displayMaxY,
              minX: 0,
              maxX: calcData.maxX,
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
                    getTitlesWidget: (value, meta) => _ChartBottomTitle(
                      value: value,
                      meta: meta,
                      calcData: calcData,
                    ),
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                enabled: canInteract,
                touchCallback: handleChartTouch,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => colors.primaryBackground,
                  getTooltipItems: buildTooltipItems,
                ),
                getTouchedSpotIndicator: buildTouchedSpotIndicators,
                getTouchLineStart: (_, __) => 0,
                getTouchLineEnd: (_, __) => double.infinity,
              ),
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
                      stops: gradient.gradientStops,
                      colors: [
                        lineColor.withValues(alpha: gradient.gradientTopAlpha),
                        lineColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChartBottomTitle extends StatelessWidget {
  const _ChartBottomTitle({
    required this.value,
    required this.meta,
    required this.calcData,
  });

  final double value;
  final TitleMeta meta;
  final ChartCalculationData calcData;

  @override
  Widget build(BuildContext context) {
    final styles = context.theme.appTextThemes;
    final colors = context.theme.appColors;

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
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/chart_calculation_data_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/chart_y_padding.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';
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

  double _calculateReservedSize(double maxY, TextStyle style) {
    const chartAnnotationPadding = 10.0;
    return calculateTextWidth(maxY.toStringAsFixed(4), style) + chartAnnotationPadding.s;
  }

  double _calculateInitialScale(int dataPointCount) {
    const maxPointsPerScreen = 35;

    if (dataPointCount < maxPointsPerScreen) {
      return 1;
    }

    return dataPointCount / maxPointsPerScreen;
  }

  /// Converts pixel coordinates to data coordinates based on transformation matrix.
  ({double startX, double endX}) _calculateVisibleDataRange(
    Matrix4 matrix,
    double drawableWidth,
    double maxX,
  ) {
    final scaleX = matrix.storage[0];
    final translateX = matrix.storage[12];
    final dataPerPixel = maxX / drawableWidth;

    final startX = ((-translateX / scaleX) * dataPerPixel).clamp(0.0, maxX);
    final endX = (((-translateX + drawableWidth) / scaleX) * dataPerPixel).clamp(0.0, maxX);

    return (startX: startX, endX: endX);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const debounceDelay = Duration(milliseconds: 150);
    const scrollAnimationDuration = Duration(milliseconds: 250);

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

    final initialScale = useMemoized(
      () => _calculateInitialScale(candles.length),
      [candles.length],
    );

    final chartKey = useMemoized(GlobalKey.new);
    final transformationController = useTransformationController(
      initialValue: Matrix4.identity()..scaleByDouble(initialScale, initialScale, 1, 1),
    );

    // Debounce timer for Y-range calculation
    final debounceTimerRef = useRef<Timer?>(null);

    // State for visible Y range (updated on scroll)
    final visibleYRange = useState<({double minY, double maxY})?>(null);

    // Track if Y-range change is from scroll (animate) vs data load (no animate)
    final isScrollTriggered = useRef(false);

    // Track if initial scroll position has been set (hide chart until positioned)
    // Initially chart renders at position 0 (start), then we move it to end position
    final isPositioned = useState(false);

    void calculateVisibleYRange() {
      // Skip if loading or chart not ready
      if (isLoading) return;
      final ctx = chartKey.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;

      // Get current scroll position and zoom level
      final matrix = transformationController.value;
      final scaleX = matrix.storage[0];
      final drawableWidth = box.size.width - reservedSize;
      if (drawableWidth <= 0 || calcData.maxX <= 0 || scaleX <= 0) return;

      // Find which data points are visible on screen (convert scroll position to data indices)
      final visibleRange = _calculateVisibleDataRange(matrix, drawableWidth, calcData.maxX);
      final startIndex = visibleRange.startX.floor();
      final endIndex = visibleRange.endX.ceil().clamp(0, candles.length - 1);

      // Get only the chart points that are currently visible
      final visibleSpots = calcData.spots.where((spot) {
        final idx = spot.x.toInt();
        return idx >= startIndex && idx <= endIndex;
      }).toList();
      if (visibleSpots.isEmpty) {
        visibleYRange.value = null;
        return;
      }

      // Find min/max Y values from visible points and add padding
      final minY = visibleSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
      final maxY = visibleSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      final newYRange = calculatePaddedYRange(minY, maxY);

      // Update Y-axis range only if it actually changed
      final currentRange = visibleYRange.value;
      if (currentRange == null ||
          currentRange.minY != newYRange.minY ||
          currentRange.maxY != newYRange.maxY) {
        visibleYRange.value = newYRange;
      }
    }

    // Listen to scroll/pan and update Y range (debounced)
    useEffect(
      () {
        void onTransformationChanged() {
          debounceTimerRef.value?.cancel();
          debounceTimerRef.value = Timer(debounceDelay, () {
            isScrollTriggered.value = true; // Mark as scroll-triggered for animation
            calculateVisibleYRange();
          });
        }

        transformationController.addListener(onTransformationChanged);

        return () {
          debounceTimerRef.value?.cancel();
          debounceTimerRef.value = null;
          transformationController.removeListener(onTransformationChanged);
        };
      },
      [transformationController, calcData, candles, reservedSize],
    );

    // Set initial transformation (scroll to end) and mark as positioned
    useEffect(
      () {
        isPositioned.value = false; // Reset on data change

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = chartKey.currentContext;
          if (ctx == null) return;

          final box = ctx.findRenderObject() as RenderBox?;
          if (box == null || !box.hasSize) return;

          final totalWidth = box.size.width;
          final drawableWidth = totalWidth - reservedSize;
          final translateX = -drawableWidth * (initialScale - 1);

          transformationController.value = Matrix4.identity()
            ..translateByDouble(translateX, 0, 0, 1)
            ..scaleByDouble(initialScale, initialScale, 1, 1);

          isPositioned.value = true; // Now safe to show
        });

        return null;
      },
      [initialScale, reservedSize],
    );

    // Calculate Y range when data loads
    useEffect(
      () {
        isScrollTriggered.value = false; // Data change, not scroll - no animation

        if (!isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            calculateVisibleYRange();
          });
        }

        return null;
      },
      [calcData, candles, isLoading],
    );

    final lineColor = isLoading ? colors.tertiaryText.withValues(alpha: 0.4) : colors.primaryAccent;
    final canInteract = !isLoading;

    final effectiveMinY = visibleYRange.value?.minY ?? calcData.chartMinY;
    final effectiveMaxY = visibleYRange.value?.maxY ?? calcData.chartMaxY;

    // Only animate Y-axis changes triggered by scroll, not by data load
    final duration = isScrollTriggered.value ? scrollAnimationDuration : Duration.zero;

    // Hide chart until initial scroll position is set (prevents visible jump)
    return Opacity(
      opacity: isPositioned.value ? 1.0 : 0.0,
      child: LineChart(
        key: chartKey,
        duration: duration,
        transformationConfig: FlTransformationConfig(
          scaleAxis: FlScaleAxis.horizontal,
          panEnabled: canInteract,
          scaleEnabled: false,
          transformationController: transformationController,
        ),
        LineChartData(
          minY: effectiveMinY,
          maxY: effectiveMaxY,
          minX: 0,
          // Add small padding so the last data point's dot renders fully (not clipped)
          maxX: calcData.maxX + 0.5,
          clipData: const FlClipData.all(),
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
          lineTouchData: LineTouchData(
            enabled: canInteract,
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

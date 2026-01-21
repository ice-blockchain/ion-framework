// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/chart_calculation_data_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/chart_y_padding.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';
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

  static const _debounceDelay = Duration(milliseconds: 150);
  static const _scrollAnimationDuration = Duration(milliseconds: 250);
  static const _longPressDuration = Duration(milliseconds: 300);
  static const _moveThreshold =
      10.0; // pixels - if moved more, cancel long press (user is scrolling)

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

    final debounceTimerRef = useRef<Timer?>(null);

    final visibleYRange = useState<({double minY, double maxY})?>(null);

    final isScrollTriggered = useRef(false);

    // Hide chart until initial scroll position is set
    final isPositioned = useState(false);

    final previousTouchedSpotIndex = useRef<int?>(null);

    final isTooltipMode = useState(false);
    final longPressTimer = useRef<Timer?>(null);
    final pointerDownPosition = useRef<Offset?>(null);

    useEffect(() => () => longPressTimer.value?.cancel(), const []);

    void calculateVisibleYRange() {
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
          debounceTimerRef.value = Timer(_debounceDelay, () {
            isScrollTriggered.value = true;
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
        isPositioned.value = false;

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

          isPositioned.value = true;
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
    final tooltipEnabled = canInteract && isTooltipMode.value;

    final displayMinY = visibleYRange.value?.minY ?? calcData.chartMinY;
    final displayMaxY = visibleYRange.value?.maxY ?? calcData.chartMaxY;

    final gradient = useChartGradient(
      chartMaxY: calcData.chartMaxY,
      displayMinY: displayMinY,
      displayMaxY: displayMaxY,
      hasVisibleRange: visibleYRange.value != null,
    );

    // Only animate Y-axis changes triggered by scroll, not by data load
    final duration = isScrollTriggered.value ? _scrollAnimationDuration : Duration.zero;

    // Handle touch events for haptic feedback when moving tooltip between data points
    void handleChartTouch(FlTouchEvent event, BaseTouchResponse? response) {
      if (!isTooltipMode.value) return;

      // Check if this is a drag/move event on the line chart
      if ((event is FlLongPressMoveUpdate || event is FlPanUpdateEvent) &&
          response is LineTouchResponse) {
        final lineResponse = response;
        final spots = lineResponse.lineBarSpots;
        if (spots == null || spots.isEmpty) return;

        // Trigger haptic only when moving to a different data point
        final currentIndex = spots.first.x.toInt();
        if (previousTouchedSpotIndex.value != currentIndex) {
          previousTouchedSpotIndex.value = currentIndex;
          HapticFeedback.lightImpact();
        }
      }
    }

    Widget buildBottomTitle(double value, TitleMeta meta) {
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

    // Hide chart until initial scroll position is set (prevents visible jump)
    return Opacity(
      opacity: isPositioned.value ? 1.0 : 0.0,
      child: _TooltipListener(
        canInteract: canInteract,
        isTooltipMode: isTooltipMode,
        longPressTimer: longPressTimer,
        pointerDownPosition: pointerDownPosition,
        previousTouchedSpotIndex: previousTouchedSpotIndex,
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
                  getTitlesWidget: buildBottomTitle,
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
        ),
      ),
    );
  }
}

// Listener widget that handles long press detection for tooltip mode.
// Manages the interaction between scrolling and tooltip display:
// - Normal scrolling: works immediately
// - Tooltip mode: activated after 300ms long press without movement
// - Haptic feedback: triggered when tooltip appears and when moving between data points
class _TooltipListener extends StatelessWidget {
  const _TooltipListener({
    required this.canInteract,
    required this.isTooltipMode,
    required this.longPressTimer,
    required this.pointerDownPosition,
    required this.previousTouchedSpotIndex,
    required this.child,
  });

  final bool canInteract;
  final ValueNotifier<bool> isTooltipMode;
  final ObjectRef<Timer?> longPressTimer;
  final ObjectRef<Offset?> pointerDownPosition;
  final ObjectRef<int?> previousTouchedSpotIndex;
  final Widget child;

  void _resetTooltipState(_) {
    longPressTimer.value?.cancel();
    isTooltipMode.value = false;
    pointerDownPosition.value = null;
    previousTouchedSpotIndex.value = null;
  }

  void _activateTooltipMode() {
    isTooltipMode.value = true;
    HapticFeedback.lightImpact();
  }

  void _handlePointerDown(PointerDownEvent event) {
    pointerDownPosition.value = event.position;
    longPressTimer.value?.cancel();
    longPressTimer.value = Timer(
      TokenAreaLineChart._longPressDuration,
      _activateTooltipMode,
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final startPos = pointerDownPosition.value;
    if (startPos == null || isTooltipMode.value) return;

    final distance = (event.position - startPos).distance;
    if (distance > TokenAreaLineChart._moveThreshold) {
      longPressTimer.value?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: canInteract ? _handlePointerDown : null,
      onPointerMove: _handlePointerMove,
      onPointerUp: _resetTooltipState,
      onPointerCancel: _resetTooltipState,
      child: child,
    );
  }
}

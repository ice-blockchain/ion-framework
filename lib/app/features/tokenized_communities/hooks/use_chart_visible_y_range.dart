// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/features/tokenized_communities/providers/chart_calculation_data_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/chart_transformation_utils.dart';
import 'package:ion/app/features/tokenized_communities/utils/chart_y_padding.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';

const _debounceDelay = Duration(milliseconds: 150);

({
  ValueNotifier<({double minY, double maxY})?> visibleYRange,
  ObjectRef<bool> isScrollTriggered,
}) useChartVisibleYRange({
  required bool isLoading,
  required GlobalKey chartKey,
  required TransformationController transformationController,
  required double reservedSize,
  required ChartCalculationData calcData,
  required List<ChartCandle> candles,
}) {
  final debounceTimerRef = useRef<Timer?>(null);
  final visibleYRange = useState<({double minY, double maxY})?>(null);
  final isScrollTriggered = useRef(false);

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
    final visibleRange = calculateVisibleDataRange(matrix, drawableWidth, calcData.maxX);
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

  return (
    visibleYRange: visibleYRange,
    isScrollTriggered: isScrollTriggered,
  );
}

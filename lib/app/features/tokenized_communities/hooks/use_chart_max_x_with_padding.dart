// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';

/// Returns the X-axis end value to pass to the chart so the last dot isn't clipped.
/// The chart accepts [minX, maxX]; we extend maxX by a small amount (in X units)
/// so there is empty space to the right of the last point. Uses RenderBox for
/// exact pixel→X conversion so the gap is consistent regardless of data count.
double useChartMaxXWithPadding({
  required GlobalKey chartKey,
  required ValueNotifier<bool> isPositioned,
  required double reservedSize,
  required double maxX,
  required int candleCount,
}) {
  // Fixed pixel padding for the endpoint dot (radius + stroke + margin)
  final dotPaddingPixels = 4.0.s;
  const maxPointsPerScreen = 35;

  // Calculate scale factor (same as in useChartTransformation)
  final scale = candleCount < maxPointsPerScreen ? 1.0 : candleCount / maxPointsPerScreen;

  // Fallback padding for initial hidden render (before RenderBox is available)
  const fallbackPadding = 0.5;

  return useMemoized(
    () {
      // During initial render, chart is hidden anyway - use fallback
      if (!isPositioned.value) {
        return maxX + fallbackPadding;
      }

      // Get actual dimensions from RenderBox
      final box = chartKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        return maxX + fallbackPadding;
      }

      // Calculate exact padding in data units based on actual widget width.
      // Must account for scale factor: scrollable charts are zoomed in,
      // so visible pixels per data unit is larger than total pixels / maxX.
      final drawableWidth = box.size.width - reservedSize;
      if (drawableWidth <= 0 || maxX <= 0) {
        return maxX + fallbackPadding;
      }

      final pixelsPerXUnit = (drawableWidth * scale) / maxX;
      final extraXUnitsForGap = dotPaddingPixels / pixelsPerXUnit;
      final chartEndX = maxX + extraXUnitsForGap;

      return chartEndX;
    },
    [isPositioned.value, maxX, candleCount, reservedSize, scale],
  );
}

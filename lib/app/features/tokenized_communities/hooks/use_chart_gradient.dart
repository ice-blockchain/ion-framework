// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';

// Calculates gradient stops and alpha for chart fill area.
// Ensures consistent gradient appearance regardless of scroll position.
({List<double>? gradientStops, double gradientTopAlpha}) useChartGradient({
  required double chartMaxY,
  required double displayMinY,
  required double displayMaxY,
  required bool hasVisibleRange,
}) {
  return useMemoized(
    () {
      // Gradient stops relative to fill area (not global) to keep appearance consistent.
      // Fill area: Top = chartMaxY, Bottom = displayMinY. Visible bottom always = 1.0.
      List<double>? gradientStops;
      var gradientTopAlpha = 0.3;
      final fillAreaRange = chartMaxY - displayMinY;
      final visibleRange = displayMaxY - displayMinY;

      if (fillAreaRange > 0 && hasVisibleRange) {
        // Detect flat line: when visible range is < 0.1% of displayed max value
        // Uses local-relative check to handle extreme spike ratios (100x+)
        final isEssentiallyFlat = visibleRange < displayMaxY * 0.001;

        if (isEssentiallyFlat) {
          // Flat line: disable fill entirely to avoid padding artifacts
          gradientTopAlpha = 0.0;
          gradientStops = [0.0, 1.0];
        } else {
          // Position gradient based on where visible area is within global fill range
          final visibleTopInFill = ((chartMaxY - displayMaxY) / fillAreaRange).clamp(0.0, 0.99);
          gradientStops = [visibleTopInFill, 1.0];
          // Alpha stays at 0.3 - gradient stops handle positioning, isFlat handles flat cases
        }
      }

      return (gradientStops: gradientStops, gradientTopAlpha: gradientTopAlpha);
    },
    [chartMaxY, displayMinY, displayMaxY, hasVisibleRange],
  );
}

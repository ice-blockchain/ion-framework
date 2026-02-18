// SPDX-License-Identifier: ice License 1.0

// Calculates Y-axis padding
// Returns 20% of the range if values differ, or 20% of the minimum value
// when all values are identical. For zero values, uses a small absolute minimum
// to prevent zero-range chart.
double calculateChartYPadding(double minY, double maxY) {
  final range = maxY - minY;

  // Only use range-based padding if range is SIGNIFICANT (> 0.1% of max value)
  // This handles floating point precision issues where range > 0 but is negligible
  if (range > maxY * 0.001) {
    return range * 0.20;
  }

  // Proportional 20% padding when all values are identical.
  // For zero values: use a small absolute minimum to prevent zero-range chart.
  // For any positive value (even extremely tiny like 0.000000000001), use proportional padding.
  if (minY == 0) {
    return 0.0001;
  }
  return minY * 0.20;
}

// Returns a record with minY and maxY values that include appropriate padding.
// The minY is clamped to 0 to prevent negative values for price charts.
({double minY, double maxY}) calculatePaddedYRange(double minY, double maxY) {
  final padding = calculateChartYPadding(minY, maxY);
  return (
    // 1% extra bottom padding prevents paddedMinY from landing exactly on
    // fl_chart's auto-calculated label interval (which excludes it via minIncluded: false).
    minY: (minY - padding * 1.01).clamp(0.0, double.infinity),
    maxY: maxY + padding,
  );
}

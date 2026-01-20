// SPDX-License-Identifier: ice License 1.0

// Calculates Y-axis padding
// Returns 20% of the range if values differ, or 5% of the minimum value
// (with a minimum of 0.0001) when all values are identical to prevent bottom flat lines.
double calculateChartYPadding(double minY, double maxY) {
  final range = maxY - minY;
  if (range > 0) {
    return range * 0.20;
  }

  // Minimum 20% padding when all values are identical
  return (minY * 0.20).clamp(0.0001, double.infinity);
}

// Returns a record with minY and maxY values that include appropriate padding.
// The minY is clamped to 0 to prevent negative values for price charts.
({double minY, double maxY}) calculatePaddedYRange(double minY, double maxY) {
  final padding = calculateChartYPadding(minY, maxY);
  return (
    minY: (minY - padding).clamp(0.0, double.infinity),
    maxY: maxY + padding,
  );
}

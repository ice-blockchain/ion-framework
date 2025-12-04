// SPDX-License-Identifier: ice License 1.0

extension TimeframeFormatting on String {
  /// Converts timeframe string to display label.
  /// Handles any timeframe format dynamically:
  /// - m5 → 5m, m15 → 15m, m30 → 30m
  /// - h1 → 1h, h4 → 4h, h6 → 6h, h24 → 24h
  /// - d3 → 3d, w2 → 2w, etc.
  String get displayLabel {
    final match = RegExp(r'^([a-zA-Z]+)(\d+)$').firstMatch(this);
    if (match == null) return this;

    final unit = match.group(1)!;
    final value = match.group(2)!;
    return '$value$unit';
  }
}

extension TimeframeSorting on String {
  /// Converts timeframe to total minutes for sorting.
  /// - m → minutes
  /// - h → hours (multiply by 60)
  /// - d → days (multiply by 60 * 24)
  /// - w → weeks (multiply by 60 * 24 * 7)
  /// Returns 999999999 for unknown formats (sorted to bottom).
  int get sortValue {
    final match = RegExp(r'^([a-zA-Z]+)(\d+)$').firstMatch(this);
    if (match == null) return 999999999; // unknown → bottom

    final unit = match.group(1)!;
    final number = int.tryParse(match.group(2)!) ?? 0;

    switch (unit) {
      case 'm':
        return number;
      case 'h':
        return number * 60;
      case 'd':
        return number * 60 * 24;
      case 'w':
        return number * 60 * 24 * 7;
      default:
        return 999999999;
    }
  }
}

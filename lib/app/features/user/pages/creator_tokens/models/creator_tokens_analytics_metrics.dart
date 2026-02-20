// SPDX-License-Identifier: ice License 1.0

enum CreatorTokensAnalyticsRange {
  day,
  week,
  month,
}

extension CreatorTokensAnalyticsRangeLabel on CreatorTokensAnalyticsRange {
  String get label {
    switch (this) {
      case CreatorTokensAnalyticsRange.day:
        return '24h';
      case CreatorTokensAnalyticsRange.week:
        return '7d';
      case CreatorTokensAnalyticsRange.month:
        return '30d';
    }
  }
}

class CreatorTokensAnalyticsMetrics {
  const CreatorTokensAnalyticsMetrics({
    this.tokensLaunched,
    this.migrated,
    this.volume,
  });

  final String? tokensLaunched;
  final String? migrated;
  final String? volume;
}

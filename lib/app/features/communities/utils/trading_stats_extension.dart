// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';

extension TradingStatsExtension on TradingStats {
  /// Calculates the net buy percentage as a percentage of total volume.
  /// Returns 0.0 if volume is zero or negative.
  double get netBuyPercent {
    if (volumeUSD <= 0) return 0;
    return (netBuy / volumeUSD) * 100;
  }
}

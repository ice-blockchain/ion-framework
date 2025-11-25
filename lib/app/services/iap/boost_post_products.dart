// SPDX-License-Identifier: ice License 1.0

/// Constants for boost post feature configuration
class BoostPostProducts {
  BoostPostProducts._();

  /// Available daily budget options in USD
  static const List<int> budgets = [1, 5, 10, 25, 50];

  /// Available duration options in days
  static const List<int> durations = [1, 2, 3, 4, 5, 6, 7];

  /// Available daily budget options as doubles (for UI sliders)
  static const List<double> budgetValues = [1.0, 5.0, 10.0, 25.0, 50.0];

  /// Minimum duration in days
  static const int minDuration = 1;

  /// Maximum duration in days
  static const int maxDuration = 7;

  /// Default budget (USD per day)
  static const double defaultBudget = 10;

  /// Default duration (days)
  static const int defaultDuration = 7;

  /// Generate product ID from budget and duration
  static String getProductId(int budget, int duration) {
    return 'boost_${budget}_$duration';
  }

  /// Generate all product IDs for boost combinations
  /// Returns 35 product IDs (5 budgets × 7 durations)
  static Set<String> generateAllProductIds() {
    return {
      for (final budget in budgets)
        for (final duration in durations) getProductId(budget, duration),
    };
  }
}

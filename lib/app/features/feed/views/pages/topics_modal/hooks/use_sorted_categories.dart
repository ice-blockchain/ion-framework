// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/features/feed/data/models/feed_interests.f.dart';

/// Sorts categories or subcategories by their weight in descending order.
/// If weights are equal, sorts them alphabetically by their display name.
Map<String, T> useSortedCategories<T>(Map<String, T> categories) {
  return useMemoized(
    () {
      final sorted = categories.entries.toList()
        ..sort((a, b) {
          final aValue = a.value;
          final bValue = b.value;

          final weightComparison = aValue is CategoryWithWeight && bValue is CategoryWithWeight
              ? bValue.weight.compareTo(aValue.weight)
              : 0;

          if (weightComparison != 0) {
            return weightComparison;
          }

          return aValue is CategoryWithDisplayName && bValue is CategoryWithDisplayName
              ? aValue.display.compareTo(bValue.display)
              : 0;
        });
      return Map.fromEntries(sorted);
    },
    [categories],
  );
}

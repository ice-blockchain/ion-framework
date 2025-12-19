// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

class AdInsertionHelper {
  AdInsertionHelper({required this.baseInterval, required this.randomDelta});

  final int baseInterval; // e.g., X
  final int randomDelta; // e.g., Y

  /// Returns indices where ads should be inserted for a list of [contentCount].
  /// Ensures spacing of roughly X ± Y between ads.
  List<int> computeInsertionIndices(int contentCount, {int startOffset = 0}) {
    final indices = <int>[];
    if (contentCount <= 0 || baseInterval <= 0) return indices;

    final rng = Random(baseInterval);

    // Initial position: It is okay for the first ad to be at index 1.
    final next = max(1, startOffset + rng.nextInt(randomDelta));
    var cursor = next;
    while (cursor < contentCount) {
      indices.add(cursor);

      // Subsequent gaps: Enforce a minimum of 2 to prevent adjacent ads (e.g., 20, 21).
      final gap = max(2, startOffset + rng.nextInt(randomDelta));
      cursor += gap;
    }
    return indices;
  }
}

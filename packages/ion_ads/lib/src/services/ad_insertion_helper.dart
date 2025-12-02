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

    final rng = Random(startOffset);
    final next = max(1, baseInterval + rng.nextInt(randomDelta * 2 + 1) - randomDelta);
    var cursor = next;
    while (cursor < contentCount) {
      indices.add(cursor);
      final gap = max(1, baseInterval + rng.nextInt(randomDelta * 2 + 1) - randomDelta);
      cursor += gap;
    }
    return indices;
  }
}

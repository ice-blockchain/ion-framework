// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

class AdInsertionHelper {
  AdInsertionHelper({required this.baseInterval, required this.randomDelta});

  final int baseInterval; // e.g., X
  final int randomDelta; // e.g., Y
  final rng = Random(DateTime.now().millisecondsSinceEpoch);
  final adIndices = <int>[];

  /// Returns indices where ads should be inserted for a list of [contentCount].
  /// Ensures spacing of roughly X ± Y between ads.
  List<int> computeInsertionIndices(int contentCount, {int startOffset = 0}) {
    if (contentCount <= 0 || baseInterval <= 0) return adIndices;

    try {
      final nextAdIndex =
          (startOffset + rng.nextInt(randomDelta) - rng.nextInt(startOffset) / 2).toInt();
      var maxIndex = contentCount + adIndices.length;
      if (adIndices.isNotEmpty && adIndices.last >= maxIndex) {
        adIndices.clear();
        maxIndex = contentCount;
      }

      var cursor = adIndices.isEmpty ? nextAdIndex : adIndices.last + nextAdIndex;
      while (cursor < maxIndex) {
        adIndices.add(cursor);

        final nextOffset = rng.nextInt(startOffset + 1);
        final gap = nextOffset + rng.nextInt(randomDelta);
        cursor += max(baseInterval, gap);
      }
    } on Object catch (_) {
      adIndices.clear();
    }

    return adIndices;
  }
}

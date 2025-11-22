// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion_token_analytics/ion_token_analytics.dart';

/// Transforms a stream of raw JSON events into a stream of sorted [TopHolder] lists.
///
/// Protocol:
/// 1. **Initial Phase**: Receives individual [TopHolder] JSON objects. Buffers them.
/// 2. **Marker**: Receives an empty JSON object `{}`. Signals end of initial phase. Emits sorted list.
/// 3. **Live Phase**: Receives [TopHolder] JSON updates. Updates the list and emits.
class TopHoldersStreamTransformer extends StreamTransformerBase<dynamic, List<TopHolder>> {
  TopHoldersStreamTransformer(this.limit);

  final int limit;

  @override
  Stream<List<TopHolder>> bind(Stream<dynamic> stream) {
    final controller = StreamController<List<TopHolder>>();
    final currentList = <TopHolder>[];
    var isSynced = false;

    final subscription = stream.listen(
      (event) {
        if (event is! Map<String, dynamic>) return;

        // 1. Check for Marker (Empty JSON)
        if (event.isEmpty) {
          isSynced = true;
          _sortAndTrim(currentList);
          controller.add(List.unmodifiable(currentList));
          return;
        }

        // 2. Parse Holder
        TopHolder? holder;
        try {
          holder = TopHolder.fromJson(event);
        } catch (_) {
          // Ignore malformed data
          return;
        }

        // 3. Handle Logic based on Phase
        if (!isSynced) {
          // Initial Phase: Just buffer
          currentList.add(holder);
        } else {
          // Live Phase: Update or Insert
          _handleUpdate(currentList, holder);
          controller.add(List.unmodifiable(currentList));
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    controller.onCancel = subscription.cancel;

    return controller.stream;
  }

  void _handleUpdate(List<TopHolder> list, TopHolder update) {
    final updateId = update.position.holder.ionConnect;
    final newRank = update.position.rank;

    // Find if user exists
    final index = list.indexWhere((h) => h.position.holder.ionConnect == updateId);

    if (index != -1) {
      final existing = list[index];
      if (existing.position.rank == newRank) {
        // Simple update (value change)
        list[index] = update;
      } else {
        // Rank change (remove and re-insert)
        list.removeAt(index);
        _insertAtRank(list, update, newRank);
      }
    } else {
      // New user
      _insertAtRank(list, update, newRank);
    }

    _sortAndTrim(list);
  }

  void _insertAtRank(List<TopHolder> list, TopHolder item, int rank) {
    // Rank is 1-based
    final targetIndex = rank - 1;
    if (targetIndex >= 0) {
      if (targetIndex < list.length) {
        list.insert(targetIndex, item);
      } else {
        list.add(item);
      }
    }
  }

  void _sortAndTrim(List<TopHolder> list) {
    // Sort by rank
    list.sort((a, b) => a.position.rank.compareTo(b.position.rank));

    // Trim to limit
    if (list.length > limit) {
      list.length = limit;
    }

    // Normalize ranks (optional, but good for consistency)
    for (var i = 0; i < list.length; i++) {
      final expectedRank = i + 1;
      if (list[i].position.rank != expectedRank) {
        list[i] = list[i].copyWith(position: list[i].position.copyWith(rank: expectedRank));
      }
    }
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/optimistic_ui/model/optimistic_message_reactions.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';

/// Sync strategy for toggling message reactions using E2EE reaction service.
class ReactionSyncStrategy implements SyncStrategy<OptimisticMessageReactions> {
  ReactionSyncStrategy({
    required this.sendReaction,
    required this.deleteReaction,
  });

  final Future<void> Function(EventReference eventReference, String emoji) sendReaction;
  final Future<void> Function(EventReference eventReference) deleteReaction;

  @override
  Future<OptimisticMessageReactions> send(
    OptimisticMessageReactions previous,
    OptimisticMessageReactions optimistic,
  ) async {
    final eventReference = optimistic.eventReference;

    // Create maps for quick lookup by emoji
    final previousMap = {for (final r in previous.reactions) r.emoji: r};
    final optimisticMap = {for (final r in optimistic.reactions) r.emoji: r};

    // Handle added or updated reactions
    for (final entry in optimisticMap.entries) {
      final emoji = entry.key;
      final optimisticReaction = entry.value;
      final optimisticMasterPubkeys = optimisticReaction.masterPubkeys;
      final previousReaction = previousMap[emoji];
      final previousMasterPubkeys = previousReaction?.masterPubkeys ?? <String>[];

      final previousSet = previousMasterPubkeys.toSet();
      final optimisticSet = optimisticMasterPubkeys.toSet();

      if (optimisticSet.isEmpty) {
        // Reaction removed
        await deleteReaction(eventReference);
      } else if (previousReaction == null) {
        // New reaction
        await sendReaction(eventReference, emoji);
      } else if (!const SetEquality<String>().equals(previousSet, optimisticSet)) {
        // Changed reaction
        if (optimisticSet.length > previousSet.length) {
          await sendReaction(eventReference, emoji);
        } else {
          await deleteReaction(eventReference);
        }
      }
    }

    return optimistic;
  }
}

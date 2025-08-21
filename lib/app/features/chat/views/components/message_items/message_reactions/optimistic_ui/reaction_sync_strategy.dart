// SPDX-License-Identifier: ice License 1.0

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
    if (optimistic.reactions.any((reaction) => reaction.masterPubkeys.isEmpty)) {
      print('ReactionSyncStrategy: No reactions to send, deleting reaction');
      await deleteReaction(optimistic.eventReference);
      return optimistic;
    }

    final previousReactionsEmoji = previous.reactions.map((reaction) => reaction.emoji).toSet();
    final optimisticReactionsEmoji = optimistic.reactions.map((reaction) => reaction.emoji).toSet();

    final newReactionAdded = optimisticReactionsEmoji.difference(previousReactionsEmoji);
    final reactionRemoved = previousReactionsEmoji.difference(optimisticReactionsEmoji);

    if (newReactionAdded.isNotEmpty && newReactionAdded.length == 1) {
      await sendReaction(optimistic.eventReference, newReactionAdded.single);
    } else if (reactionRemoved.isNotEmpty && reactionRemoved.length == 1) {
      await deleteReaction(optimistic.eventReference);
    }

    return optimistic;
  }
}

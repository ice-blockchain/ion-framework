// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/chat/model/message_reaction.f.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/optimistic_ui/model/optimistic_message_reactions.f.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_intent.dart';

/// Intent to toggle reaction state for a message.
final class ToggleReactionIntent implements OptimisticIntent<OptimisticMessageReactions> {
  ToggleReactionIntent({
    required this.emoji,
    required this.currentMasterPubkey,
  });

  final String emoji;
  final String currentMasterPubkey;

  @override
  OptimisticMessageReactions optimistic(OptimisticMessageReactions current) {
    final reactions = current.reactions.map((reaction) {
      if (reaction.emoji != emoji) return reaction;

      final hasReacted = reaction.masterPubkeys.contains(currentMasterPubkey);
      final updatedPubkeys = hasReacted
          ? reaction.masterPubkeys.where((pubkey) => pubkey != currentMasterPubkey).toList()
          : [...reaction.masterPubkeys, currentMasterPubkey];

      return reaction.copyWith(masterPubkeys: updatedPubkeys);
    }).toList();

    // Check if emoji not found in existing reactions (new reaction)
    final emojiExists = current.reactions.any((r) => r.emoji == emoji);
    if (!emojiExists) {
      reactions.add(MessageReaction(emoji: emoji, masterPubkeys: [currentMasterPubkey]));
    }

    return current.copyWith(reactions: reactions);
  }

  @override
  Future<OptimisticMessageReactions> sync(
    OptimisticMessageReactions prev,
    OptimisticMessageReactions next,
  ) async {
    throw UnimplementedError('Sync is handled by strategy');
  }
}

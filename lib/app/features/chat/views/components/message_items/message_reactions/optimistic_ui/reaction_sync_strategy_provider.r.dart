// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/e2ee_delete_event_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_e2ee_reaction_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/optimistic_ui/reaction_sync_strategy.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reaction_sync_strategy_provider.r.g.dart';

@riverpod
ReactionSyncStrategy reactionSyncStrategy(Ref ref) {
  return ReactionSyncStrategy(
    sendReaction: (eventReference, emoji) async {
      // Get the event message from the database
      final eventMessageDao = ref.read(eventMessageDaoProvider);
      final eventMessage = await eventMessageDao.getByReference(eventReference);

      final e2eeReactionService = await ref.read(sendE2eeReactionServiceProvider.future);
      await e2eeReactionService.sendReaction(content: emoji, kind14Rumor: eventMessage);
    },
    deleteReaction: (eventReference, emoji) async {
      final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

      if (currentUserMasterPubkey == null) return;

      final userReactionEvent =
          await ref.read(conversationMessageReactionDaoProvider).getUserReactionReference(
                emoji: emoji,
                eventReference: eventReference,
                masterPubkey: currentUserMasterPubkey,
              );

      if (userReactionEvent == null) return;

      final eventMessageDao = ref.read(eventMessageDaoProvider);
      final eventMessage = await eventMessageDao.getByReference(eventReference);

      if (userReactionEvent is ImmutableEventReference) {
        await ref.read(e2eeDeleteReactionNotifierProvider.notifier).deleteReaction(
              reactionEventReference: userReactionEvent,
              participantsMasterPubkeys: eventMessage.participantsMasterPubkeys,
            );
      }
    },
  );
}

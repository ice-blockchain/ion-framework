// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/optimistic_ui/message_reactions_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/emoji_message/emoji_message.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';

part 'components/message_reaction_chip.dart';

class MessageReactions extends HookConsumerWidget {
  const MessageReactions({
    required this.isMe,
    required this.eventMessage,
    super.key,
  });

  final bool isMe;
  final EventMessage eventMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMasterPubkey = ref.watch(currentPubkeySelectorProvider);
    final eventReference = useMemoized(
      () => EncryptedDirectMessageEntity.fromEventMessage(eventMessage).toEventReference(),
      [eventMessage],
    );

    final reactions =
        ref.watch(messageReactionWatchProvider(eventReference)).valueOrNull?.reactions.toList() ??
            [];

    return Padding(
      padding: EdgeInsetsDirectional.only(top: 8.0.s),
      child: Wrap(
        spacing: 0.0.s,
        runSpacing: 4.0.s,
        children: reactions.map((reaction) {
          final isCurrentUserHasReaction = useMemoized(
            () => reaction.masterPubkeys.contains(currentMasterPubkey),
            [reaction.masterPubkeys, currentMasterPubkey],
          );

          if (reaction.masterPubkeys.isEmpty) {
            return const SizedBox.shrink();
          }

          return _MessageReactionChip(
            isMe: isMe,
            emoji: reaction.emoji,
            masterPubkeys: reaction.masterPubkeys,
            currentUserHasReaction: isCurrentUserHasReaction,
            onTap: () {
              if (currentMasterPubkey == null) return;

              ref.read(toggleReactionNotifierProvider.notifier).toggle(
                    emoji: reaction.emoji,
                    eventReference: eventReference,
                    currentUserMasterPubkey: currentMasterPubkey,
                  );
            },
          );
        }).toList(),
      ),
    );
  }
}

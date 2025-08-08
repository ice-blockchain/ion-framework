// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/e2ee_delete_event_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_e2ee_reaction_provider.r.dart';
import 'package:ion/app/features/chat/model/message_reaction_group.f.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/emoji_message/emoji_message.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';

part 'components/message_reaction_chip.dart';

class MessageReactions extends ConsumerWidget {
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

    final reactions =
        ref.watch(conversationMessageReactionDaoProvider).messageReactions(eventMessage);

    return StreamBuilder<List<MessageReactionGroup>>(
      stream: reactions,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return HookBuilder(
            builder: (context) => Padding(
              padding: EdgeInsetsDirectional.only(top: 8.0.s),
              child: Wrap(
                spacing: 0.0.s,
                runSpacing: 4.0.s,
                children: [
                  ...snapshot.data!.map((reactionGroup) {
                    final reactionMasterPubkeys =
                        reactionGroup.eventMessages.map((e) => e.masterPubkey).toList();

                    final isCurrentUserHasReaction = useMemoized(
                      () => reactionMasterPubkeys.contains(currentMasterPubkey),
                      [reactionMasterPubkeys, currentMasterPubkey],
                    );

                    return _MessageReactionChip(
                      isMe: isMe,
                      emoji: reactionGroup.emoji,
                      masterPubkeys: reactionMasterPubkeys,
                      currentUserHasReaction: isCurrentUserHasReaction,
                      onTap: () async {
                        final messageEntity =
                            ReplaceablePrivateDirectMessageEntity.fromEventMessage(
                          eventMessage,
                        );

                        if (isCurrentUserHasReaction) {
                          final userReactionEventMessage = reactionGroup.eventMessages.firstWhere(
                            (e) => e.masterPubkey == currentMasterPubkey,
                          );
                          ref.read(
                            e2eeDeleteReactionProvider(
                              reactionEvent: userReactionEventMessage,
                              participantsMasterPubkeys: messageEntity.allPubkeys,
                            ),
                          );
                        } else {
                          final e2eeReactionService =
                              await ref.read(sendE2eeReactionServiceProvider.future);
                          await e2eeReactionService.sendReaction(
                            content: reactionGroup.emoji,
                            kind14Rumor: eventMessage,
                          );
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/hooks/use_combined_conversation_names.dart';
import 'package:ion/app/features/chat/model/message_type.dart';
import 'package:ion/app/features/chat/providers/conversations_provider.r.dart';
import 'package:ion/app/features/chat/providers/muted_conversations_provider.r.dart';
import 'package:ion/app/features/chat/providers/unread_message_count_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/archive_state_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/conversations_edit_mode_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_tile/recent_chat_tile.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class ArchiveChatTile extends HookConsumerWidget {
  const ArchiveChatTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditMode = ref.watch(conversationsEditModeProvider);
    final conversations = ref.watch(archivedConversationsProvider).valueOrNull ?? [];

    final unreadMessagesCount =
        ref.watch(getAllUnreadMessagesCountInArchiveProvider).valueOrNull ?? 0;

    final combinedConversationNames = useCombinedConversationNames(conversations, ref);

    final latestMessageAt = useMemoized(
      () => conversations.isEmpty
          ? null
          : conversations
              .map((c) => c.latestMessage?.createdAt.toDateTime ?? c.joinedAt.toDateTime)
              .reduce((a, b) => a.isAfter(b) ? a : b),
      [conversations],
    );

    final mutedConversationIds = ref.watch(mutedConversationsProvider).valueOrNull;
    final hasMutedConversation = useMemoized(
      () {
        final archiveConversationIds = conversations.map((e) => e.conversationId).toList();
        return mutedConversationIds?.any(archiveConversationIds.contains) ?? false;
      },
      [conversations, mutedConversationIds],
    );

    if (conversations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.0.s),
      child: GestureDetector(
        onTap: () async {
          if (!isEditMode) {
            ref.read(archiveStateProvider.notifier).value = true;
            await ArchivedChatsMainRoute().push<void>(context);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Flexible(
              child: Row(
                children: [
                  Avatar(
                    imageWidget: Assets.svg.avatarArchive.icon(),
                    size: 48.0.s,
                  ),
                  SizedBox(width: 12.0.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              context.i18n.common_archive,
                              style: context.theme.appTextThemes.subtitle3.copyWith(
                                color: context.theme.appColors.primaryText,
                              ),
                            ),
                            if (latestMessageAt != null)
                              ChatTimestamp(
                                latestMessageAt,
                              ),
                          ],
                        ),
                        SizedBox(height: 2.0.s),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (combinedConversationNames == null)
                              const IONLoadingIndicator()
                            else
                              Expanded(
                                child: ChatPreview(
                                  lastMessageContent: combinedConversationNames,
                                  maxLines: 1,
                                  messageType: MessageType.text,
                                ),
                              ),
                            UnreadCountBadge(
                              unreadCount: unreadMessagesCount,
                              isMuted: hasMutedConversation,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

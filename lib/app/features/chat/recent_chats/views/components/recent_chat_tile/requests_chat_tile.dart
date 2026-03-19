// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/hooks/use_combined_conversation_names.dart';
import 'package:ion/app/features/chat/model/message_type.dart';
import 'package:ion/app/features/chat/recent_chats/providers/conversations_edit_mode_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/request_conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_tile/chat_folder_tile.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_tile/recent_chat_tile.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class RequestsChatTile extends HookConsumerWidget {
  const RequestsChatTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditMode = ref.watch(conversationsEditModeProvider);
    final conversations = ref.watch(requestConversationsProvider).valueOrNull ?? [];

    if (conversations.isEmpty) {
      return const SizedBox.shrink();
    }

    final combinedConversationNames = useCombinedConversationNames(conversations, ref);

    final latestMessageAt = useMemoized(
      () => conversations
          .map((c) => c.latestMessage?.createdAt.toDateTime ?? c.joinedAt.toDateTime)
          .reduce((a, b) => a.isAfter(b) ? a : b),
      [conversations],
    );

    return ChatFolderTile(
      avatarIcon: Assets.svg.iconChatRequests.icon(),
      title: context.i18n.chat_requests_title,
      timestamp: latestMessageAt,
      onTap: () async {
        if (!isEditMode) {
          await RequestsChatsMainRoute().push<void>(context);
        }
      },
      previewContent: Expanded(
        child: ChatPreview(
          lastMessageContent: combinedConversationNames ?? '',
          maxLines: 1,
          messageType: MessageType.text,
        ),
      ),
      trailing: UnreadCountBadge(
        unreadCount: conversations.length,
        isMuted: false,
      ),
    );
  }
}

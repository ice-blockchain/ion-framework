// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/hooks/use_combined_conversation_names.dart';
import 'package:ion/app/features/chat/model/message_type.dart';
import 'package:ion/app/features/chat/recent_chats/providers/conversations_edit_mode_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/request_conversations_provider.r.dart';
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

    return SizedBox(
      height: RecentChatTile.tileHeight,
      child: GestureDetector(
        onTap: () async {
          if (!isEditMode) {
            await RequestsChatsMainRoute().push<void>(context);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: 16.0.s,
            top: 8.0.s,
            end: 16.0.s,
            bottom: 8.0.s,
          ),
          child: Row(
            children: [
              Avatar(
                imageWidget: Assets.svg.iconChatRequests.icon(),
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
                          context.i18n.chat_requests_title,
                          style: context.theme.appTextThemes.subtitle3.copyWith(
                            color: context.theme.appColors.primaryText,
                          ),
                        ),
                        ChatTimestamp(latestMessageAt),
                      ],
                    ),
                    SizedBox(height: 2.0.s),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ChatPreview(
                            lastMessageContent: combinedConversationNames ?? '',
                            maxLines: 1,
                            messageType: MessageType.text,
                          ),
                        ),
                        UnreadCountBadge(unreadCount: conversations.length, isMuted: false),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

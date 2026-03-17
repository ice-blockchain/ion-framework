// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/conversations_edit_mode_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_conversations_ids_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_tile/recent_chat_actions.dart';
import 'package:ion/generated/assets.gen.dart';

class ConversationArchiveButton extends ConsumerWidget {
  const ConversationArchiveButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedConversations = ref.watch(selectedConversationsProvider);

    final conversationsToManage = selectedConversations.isEmpty
        ? ref.read(notArchivedConversationsProvider).valueOrNull ?? []
        : selectedConversations;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final conversationIds =
            conversationsToManage.map((e) => e.conversationId).toList();

        ref.read(selectedConversationsProvider.notifier).clear();
        ref.read(conversationsEditModeProvider.notifier).editMode = false;

        // Show toast after edit bar unmounts so it is visible
        final message = context.i18n.chat_archived;
        final archiveIcon = Assets.svg.iconChatArchive.icon(size: 16.0.s);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          executeArchiveOrUnarchiveWithToast(
            ref: ref,
            conversationIds: conversationIds,
            message: message,
            icon: archiveIcon,
          );
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Assets.svg.iconChatArchive.icon(
            color: conversationsToManage.isNotEmpty
                ? context.theme.appColors.primaryAccent
                : context.theme.appColors.tertiaryText,
            size: 20.0.s,
          ),
          SizedBox(width: 4.0.s),
          Flexible(
            child: Text(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              selectedConversations.isEmpty
                  ? context.i18n.common_archive_all
                  : context.i18n.common_archive,
              style: context.theme.appTextThemes.body2.copyWith(
                color: conversationsToManage.isNotEmpty
                    ? context.theme.appColors.primaryAccent
                    : context.theme.appColors.tertiaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

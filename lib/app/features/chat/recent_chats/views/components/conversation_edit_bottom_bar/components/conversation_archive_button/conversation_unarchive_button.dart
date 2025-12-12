// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/conversations_edit_mode_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_conversations_ids_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/toggle_archive_conversation_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class ConversationUnarchiveButton extends ConsumerWidget {
  const ConversationUnarchiveButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedConversations = ref.watch(selectedConversationsProvider);

    final conversationsToManage = selectedConversations.isEmpty
        ? ref.read(archivedConversationsProvider).valueOrNull ?? []
        : selectedConversations;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        unawaited(
          ref
              .read(toggleArchivedConversationsProvider.notifier)
              .toggleConversations(conversationsToManage.map((e) => e.conversationId).toList()),
        );
        ref.read(conversationsEditModeProvider.notifier).editMode = false;
        ref.read(selectedConversationsProvider.notifier).clear();
        if (context.mounted && context.canPop()) {
          context.pop();
        }
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
                  ? context.i18n.common_unarchive
                  : context.i18n.common_unarchive_single,
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

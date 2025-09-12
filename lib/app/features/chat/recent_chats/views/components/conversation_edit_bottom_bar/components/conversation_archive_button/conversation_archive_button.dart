// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/conversations_edit_mode_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_conversations_ids_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/toggle_archive_conversation_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class ConversationArchiveButton extends ConsumerWidget {
  const ConversationArchiveButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedConversations = ref.watch(selectedConversationsProvider);

    final conversationsToManage = selectedConversations.isEmpty
        ? (ref
                .read(conversationsProvider)
                .value
                ?.where((conversation) => !conversation.isArchived)
                .toList() ??
            [])
        : selectedConversations;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        unawaited(
          ref
              .read(toggleArchivedConversationsProvider.notifier)
              .toggleConversations(conversationsToManage),
        );

        ref.read(selectedConversationsProvider.notifier).clear();
        ref.read(conversationsEditModeProvider.notifier).editMode = false;
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

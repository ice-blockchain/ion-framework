// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/message_notification/models/message_notification.f.dart';
import 'package:ion/app/components/message_notification/providers/message_notification_notifier_provider.r.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/conversations_provider.r.dart';
import 'package:ion/app/features/chat/providers/muted_conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/toggle_archive_conversation_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/undo_archive_button.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

enum RecentChatActionKind {
  archive,
  unarchive,
  mute,
  unmute,
  delete,
}

class RecentChatActionItem {
  const RecentChatActionItem({
    required this.kind,
    required this.label,
    required this.icon,
    required this.onSelected,
  });

  final RecentChatActionKind kind;
  final String label;
  final String icon;

  final Future<bool> Function() onSelected;

  bool get isDestructive => kind == RecentChatActionKind.delete;
}

List<RecentChatActionItem> buildRecentChatActions({
  required BuildContext context,
  required WidgetRef ref,
  required ConversationListItem conversation,
}) {
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  final receiverMasterPubkey = conversation.receiverMasterPubkey(currentUserMasterPubkey);

  final archivedConversationIds = ref
          .watch(archivedConversationsProvider)
          .valueOrNull
          ?.map((item) => item.conversationId)
          .toSet() ??
      <String>{};
  final isArchived = archivedConversationIds.contains(conversation.conversationId);

  final isMuted =
      ref.watch(mutedConversationsProvider).valueOrNull?.contains(conversation.conversationId) ??
          false;

  final canMute =
      !isArchived && receiverMasterPubkey != null && conversation.type == ConversationType.oneToOne;

  return [
    RecentChatActionItem(
      kind: RecentChatActionKind.delete,
      label: context.i18n.button_delete,
      icon: Assets.svg.iconBlockDelete,
      onSelected: () async {
        final deleted = await DeleteConversationRoute(
              conversationIds: [conversation.conversationId],
            ).push<bool>(context) ??
            false;
        return deleted;
      },
    ),
    if (canMute)
      RecentChatActionItem(
        kind: isMuted ? RecentChatActionKind.unmute : RecentChatActionKind.mute,
        label: isMuted ? context.i18n.button_unmute : context.i18n.button_mute,
        icon: isMuted ? Assets.svg.iconChannelUnmute : Assets.svg.iconChannelMute,
        onSelected: () async {
          final muteConversationService = await ref.read(muteConversationServiceProvider.future);
          await muteConversationService.toggleMutedConversation(receiverMasterPubkey);
          return true;
        },
      ),
    RecentChatActionItem(
      kind: isArchived ? RecentChatActionKind.unarchive : RecentChatActionKind.archive,
      label: isArchived ? context.i18n.common_unarchive_single : context.i18n.common_add_to_archive,
      icon: Assets.svg.iconChatArchive,
      onSelected: () async {
        final message = isArchived ? context.i18n.chat_unarchived : context.i18n.chat_archived;
        final archiveIcon = Assets.svg.iconChatArchive.icon(size: 16.0.s);

        executeArchiveOrUnarchiveWithToast(
          ref: ref,
          conversationIds: [conversation.conversationId],
          message: message,
          icon: archiveIcon,
        );

        return true;
      },
    ),
  ];
}

void executeArchiveOrUnarchiveWithToast({
  required WidgetRef ref,
  required List<String> conversationIds,
  required String message,
  required Widget icon,
}) {
  final toggleNotifier = ref.read(toggleArchivedConversationsProvider.notifier);
  final messageNotifier = ref.read(messageNotificationNotifierProvider.notifier);

  toggleNotifier.toggleConversations(conversationIds);
  messageNotifier.show(
    MessageNotification(
      message: message,
      icon: icon,
      interactive: true,
      suffixWidget: UndoArchiveButton(
        onTap: () {
          toggleNotifier.toggleConversations(conversationIds);
          messageNotifier.dismiss();
        },
      ),
    ),
  );
}

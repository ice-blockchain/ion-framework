// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/message_notification/models/message_notification.f.dart';
import 'package:ion/app/components/message_notification/providers/message_notification_notifier_provider.r.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/recent_chats/providers/toggle_archive_conversation_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/undo_archive_button.dart';
import 'package:ion/generated/assets.gen.dart';

void executeArchiveOrUnarchiveWithToast({
  required BuildContext context,
  required WidgetRef ref,
  required List<String> conversationIds,
  required bool isArchived,
  bool deferToNextFrame = false,
}) {
  void showToast() {
    final toggleNotifier = ref.read(toggleArchivedConversationsProvider.notifier);
    final messageNotifier = ref.read(messageNotificationNotifierProvider.notifier);

    toggleNotifier.toggleConversations(conversationIds);
    messageNotifier.show(
      MessageNotification(
        message: isArchived ? context.i18n.chat_unarchived : context.i18n.chat_archived,
        icon: Assets.svg.iconChatArchive.icon(size: 16.0.s),
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

  if (deferToNextFrame) {
    WidgetsBinding.instance.addPostFrameCallback((_) => showToast());
  } else {
    showToast();
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/recent_chats/providers/archive_state_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/request_state_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/conversation_edit_bottom_bar/components/conversation_archive_button/conversation_archive_button.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/conversation_edit_bottom_bar/components/conversation_archive_button/conversation_unarchive_button.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/conversation_edit_bottom_bar/components/conversation_delete_button/conversation_delete_button.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/conversation_edit_bottom_bar/components/conversation_read_all_button/conversation_read_all_button.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/conversation_edit_bottom_bar/components/request_conversation_edit_bottom_bar.dart';

class ConversationEditBottomBar extends ConsumerWidget {
  const ConversationEditBottomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveOpened = ref.watch(archiveStateProvider).falseOrValue;
    final requestsOpened = ref.watch(requestStateProvider).falseOrValue;

    return PositionedDirectional(
      top: 0,
      start: 0,
      end: 0,
      bottom: 0,
      child: Container(
        alignment: Alignment.topCenter,
        color: context.theme.appColors.secondaryBackground,
        padding: EdgeInsetsDirectional.only(top: 16.0.s, start: 16.0.s, end: 16.0.s),
        child: requestsOpened
            ? const RequestConversationEditBottomBar()
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(child: ConversationReadAllButton()),
                  if (archiveOpened)
                    const Expanded(child: ConversationUnarchiveButton())
                  else
                    const Expanded(child: ConversationArchiveButton()),
                  const Expanded(child: ConversationDeleteButton()),
                ],
              ),
      ),
    );
  }
}

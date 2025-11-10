// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/modal_sheets/simple_modal_sheet.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class ClearGroupMessagesConfirmModal extends ConsumerWidget {
  const ClearGroupMessagesConfirmModal({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonMinimalSize = Size(56.0.s, 56.0.s);

    return SimpleModalSheet.alert(
      iconAsset: Assets.svg.actionGroupClearmessage,
      title: context.i18n.group_clear_messages_confirm_title,
      description: context.i18n.group_clear_messages_confirm_description,
      button: ScreenSideOffset.small(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Button.compact(
                type: ButtonType.outlined,
                label: Text(context.i18n.button_cancel),
                onPressed: context.pop,
                minimumSize: buttonMinimalSize,
              ),
            ),
            SizedBox(width: 15.0.s),
            Expanded(
              child: Button.compact(
                label: Text(context.i18n.group_clear_messages),
                onPressed: () async {
                  //todo add clear messages logic
                  context.pop();
                  // // Get all messages for this conversation
                  // final messages = ref
                  //     .read(conversationMessagesProvider(conversationId, ConversationType.group))
                  //     .valueOrNull;
                  //
                  // if (messages != null && messages.isNotEmpty) {
                  //   // Get all EventMessage objects from the messages
                  //   final eventMessages = messages.values
                  //       .expand((messageList) => messageList)
                  //       .toList();
                  //
                  //   // Delete all messages using the E2EE delete provider
                  //   if (eventMessages.isNotEmpty) {
                  //     ref.read(
                  //       e2eeDeleteMessageProvider(
                  //         messageEvents: eventMessages,
                  //         forEveryone: true,
                  //       ),
                  //     );
                  //   }
                  // }
                },
                minimumSize: buttonMinimalSize,
                backgroundColor: context.theme.appColors.attentionRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

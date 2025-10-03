// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/conversations_edit_mode_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_conversations_ids_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class ConversationDeleteButton extends ConsumerWidget {
  const ConversationDeleteButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedConversations = ref.watch(selectedConversationsProvider);

    final conversationsToManage = selectedConversations.isEmpty
        ? (ref.read(conversationsProvider).value ?? [])
        : selectedConversations;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await DeleteConversationRoute(
          conversationIds: conversationsToManage.map((e) => e.conversationId).toList(),
        ).push<void>(context);

        if (context.mounted) {
          ref.invalidate(selectedConversationsProvider);
          ref.read(conversationsEditModeProvider.notifier).editMode = false;
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Assets.svg.iconBlockDelete.icon(
            color: conversationsToManage.isNotEmpty
                ? context.theme.appColors.attentionRed
                : context.theme.appColors.tertiaryText,
            size: 20.0.s,
          ),
          SizedBox(width: 4.0.s),
          Flexible(
            child: Text(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              selectedConversations.isNotEmpty
                  ? context.i18n.button_delete
                  : context.i18n.button_delete_all,
              style: context.theme.appTextThemes.body2.copyWith(
                color: conversationsToManage.isNotEmpty
                    ? context.theme.appColors.attentionRed
                    : context.theme.appColors.tertiaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

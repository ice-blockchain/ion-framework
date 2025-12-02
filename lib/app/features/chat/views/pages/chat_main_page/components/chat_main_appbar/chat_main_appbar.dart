// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/conversations_edit_mode_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_conversations_ids_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_text_button.dart';
import 'package:ion/generated/assets.gen.dart';

class ChatMainAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ChatMainAppBar({required this.scrollController, super.key});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editMode = ref.watch(conversationsEditModeProvider);
    final hasConversations = ref
            .watch(conversationsProvider)
            .valueOrNull
            ?.where((c) => !c.isArchived && c.latestMessage != null)
            .toList()
            .isNotEmpty ??
        false;

    return NavigationAppBar.screen(
      scrollController: scrollController,
      leading: NavigationTextButton(
        label: editMode ? context.i18n.core_done : context.i18n.button_edit,
        textStyle: context.theme.appTextThemes.subtitle2.copyWith(
          color: hasConversations
              ? context.theme.appColors.primaryAccent
              : context.theme.appColors.sheetLine,
        ),
        onPressed: hasConversations
            ? () {
                ref.read(conversationsEditModeProvider.notifier).editMode = !editMode;
                ref.read(selectedConversationsProvider.notifier).clear();
              }
            : null,
      ),
      title: Text(
        context.i18n.chat_title,
        style: context.theme.appTextThemes.subtitle2,
      ),
      actions: [
        AnimatedOpacity(
          opacity: editMode ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Assets.svg.iconEditLink.icon(
              size: NavigationAppBar.actionButtonSide,
            ),
            onPressed: () {
              if (!editMode) {
                NewChatModalRoute().push<void>(context);
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(NavigationAppBar.screenHeaderHeight);
}

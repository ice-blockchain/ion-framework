// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/archive_state_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/conversations_edit_mode_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_conversations_ids_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_skeleton/recent_chat_skeleton.dart';
import 'package:ion/app/features/chat/recent_chats/views/pages/recent_chats_empty_page/recent_chats_empty_page.dart';
import 'package:ion/app/features/chat/recent_chats/views/pages/recent_chats_timeline_page/recent_chats_archive_timeline_page.dart';
import 'package:ion/app/hooks/use_route_presence.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_text_button.dart';

class ArchivedChatsMainPage extends HookConsumerWidget {
  const ArchivedChatsMainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    final editMode = ref.watch(conversationsEditModeProvider);

    useRoutePresence(
      onBecameInactive: () {
        ref.read(archiveStateProvider.notifier).value = false;
      },
    );

    return Scaffold(
      appBar: NavigationAppBar.screen(
        onBackPress: () {
          ref.read(conversationsEditModeProvider.notifier).editMode = false;
          ref.read(selectedConversationsProvider.notifier).clear();
          context.pop();
        },
        title: Text(context.i18n.common_archive),
        actions: [
          NavigationTextButton(
            label: editMode ? context.i18n.core_done : context.i18n.button_edit,
            textStyle: context.theme.appTextThemes.subtitle2.copyWith(
              color: context.theme.appColors.primaryAccent,
            ),
            onPressed: () {
              ref.read(conversationsEditModeProvider.notifier).editMode = !editMode;
              ref.read(selectedConversationsProvider.notifier).clear();
            },
          ),
        ],
      ),
      body: conversations.when(
        data: (data) {
          if (data.isEmpty) {
            return ScreenSideOffset.small(
              child: const RecentChatsEmptyPage(),
            );
          }
          return const RecentChatsArchiveTimelinePage();
        },
        loading: () {
          return ScreenSideOffset.small(
            child: const RecentChatSkeleton(),
          );
        },
        error: (_, __) {
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

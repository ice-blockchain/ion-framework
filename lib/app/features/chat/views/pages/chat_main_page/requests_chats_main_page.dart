// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/recent_chats/providers/conversations_edit_mode_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/request_conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/request_state_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_conversations_ids_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_skeleton/recent_chat_skeleton.dart';
import 'package:ion/app/features/chat/recent_chats/views/pages/recent_chats_empty_page/recent_chats_empty_page.dart';
import 'package:ion/app/features/chat/recent_chats/views/pages/recent_chats_timeline_page/recent_chats_requests_timeline_page.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/hooks/use_route_presence.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_text_button.dart';

class RequestsChatsMainPage extends HookConsumerWidget {
  const RequestsChatsMainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(requestConversationsProvider);
    final editMode = ref.watch(conversationsEditModeProvider);
    final hasRequests = requests.valueOrNull?.isNotEmpty ?? false;

    void resetRequestsUiState() {
      ref.read(conversationsEditModeProvider.notifier).editMode = false;
      ref.read(selectedConversationsProvider.notifier).clear();
      ref.read(requestStateProvider.notifier).value = false;
    }

    void popToMainChatsIfNoRequests({required bool hasNoRequests}) {
      if (!hasNoRequests || !context.mounted || !context.isCurrentRoute || !context.canPop()) {
        return;
      }

      resetRequestsUiState();
      context.pop();
    }

    ref.listen(requestConversationsProvider, (_, next) {
      final hasNoRequests = next.valueOrNull?.isEmpty ?? false;
      if (!hasNoRequests) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        popToMainChatsIfNoRequests(hasNoRequests: hasNoRequests);
      });
    });

    useRoutePresence(
      onBecameInactive: resetRequestsUiState,
      onBecameActive: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final hasNoRequests =
              ref.read(requestConversationsProvider).valueOrNull?.isEmpty ?? false;
          popToMainChatsIfNoRequests(hasNoRequests: hasNoRequests);
        });
      },
    );

    useOnInit(
      () {
        ref.read(requestStateProvider.notifier).value = true;
      },
    );

    return Scaffold(
      appBar: NavigationAppBar.screen(
        onBackPress: () {
          resetRequestsUiState();
          context.pop();
        },
        title: Text(context.i18n.chat_requests_title),
        actions: [
          NavigationTextButton(
            label: editMode ? context.i18n.core_done : context.i18n.button_edit,
            textStyle: context.theme.appTextThemes.subtitle2.copyWith(
              color: hasRequests
                  ? context.theme.appColors.primaryAccent
                  : context.theme.appColors.sheetLine,
            ),
            onPressed: hasRequests
                ? () {
                    ref.read(conversationsEditModeProvider.notifier).editMode = !editMode;
                    ref.read(selectedConversationsProvider.notifier).clear();
                  }
                : null,
          ),
        ],
      ),
      body: ScreenSideOffset.small(
        child: requests.when(
          data: (data) {
            if (data.isEmpty) {
              return const RecentChatsEmptyPage();
            }
            return const RecentChatsRequestsTimelinePage();
          },
          loading: () => const RecentChatSkeleton(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

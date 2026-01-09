// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/features/chat/providers/conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_skeleton/recent_chat_skeleton.dart';
import 'package:ion/app/features/chat/recent_chats/views/pages/recent_chats_empty_page/recent_chats_empty_page.dart';
import 'package:ion/app/features/chat/recent_chats/views/pages/recent_chats_timeline_page/recent_chats_timeline_page.dart';
import 'package:ion/app/features/chat/views/pages/chat_main_page/components/chat_main_appbar/chat_main_appbar.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_dialog_notifier_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/creator_token_is_live_dialog.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';

class ChatMainPage extends HookConsumerWidget {
  const ChatMainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useOnInit(() {
      ref.read(uiEventQueueNotifierProvider.notifier).emit(const CreatorTokenIsLiveDialogEvent());
    });
    _useCheckDeviceKeypairDialog(ref);

    final scrollController = useScrollController();

    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: ChatMainAppBar(scrollController: scrollController),
      body: ScrollToTopWrapper(
        scrollController: scrollController,
        child: ScreenSideOffset.small(
          child: conversations.when(
            data: (data) {
              if (data.isEmpty) {
                return const RecentChatsEmptyPage();
              }
              return RecentChatsTimelinePage(
                conversations: data,
                scrollController: scrollController,
              );
            },
            error: (error, stackTrace) => const SizedBox(),
            loading: () => const RecentChatSkeleton(),
          ),
        ),
      ),
    );
  }

  void _useCheckDeviceKeypairDialog(WidgetRef ref) {
    useOnInit(() async {
      final dialogProvider = ref.read(deviceKeypairDialogNotifierProvider.notifier);
      final dialogState = await dialogProvider.getDialogState();

      if (dialogState == null || !ref.context.mounted) {
        return;
      }

      dialogProvider.markDialogShown();
      unawaited(DeviceKeypairDialogRoute(state: dialogState).push(ref.context));
    });
  }
}

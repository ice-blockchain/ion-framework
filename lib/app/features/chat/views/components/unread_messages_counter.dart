// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/badge/providers/app_badge_counter_provider.r.dart';
import 'package:ion/app/features/chat/providers/manual_unread_conversations_provider.r.dart';
import 'package:ion/app/features/chat/providers/unread_message_count_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';

class UnreadMessagesCounter extends HookConsumerWidget {
  const UnreadMessagesCounter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalUnreadMessagesCount = ref.watch(getAllUnreadMessagesCountProvider).valueOrNull ?? 0;
    final manuallyUnreadConversationIds = ref.watch(manualUnreadConversationsProvider);

    var manualOnlyUnreadCount = 0;
    for (final conversationId in manuallyUnreadConversationIds) {
      final unreadForConversationState = ref.watch(getUnreadMessagesCountProvider(conversationId));

      // Avoid counting manual unread while the per-conversation unread stream
      // is still loading, otherwise we can temporarily overcount.
      if (!unreadForConversationState.hasValue) {
        continue;
      }

      final unreadForConversation = unreadForConversationState.valueOrNull ?? 0;
      if (unreadForConversation == 0) {
        manualOnlyUnreadCount += 1;
      }
    }

    final unreadMessagesCount = totalUnreadMessagesCount + manualOnlyUnreadCount;

    useOnInit(
      () async {
        final appBadgeCounter = await ref.read(appBadgeCounterProvider.future);
        await appBadgeCounter?.setBadgeCount(unreadMessagesCount, CounterCategory.chat);
        await appBadgeCounter?.clearUnreadConversations();
      },
      [unreadMessagesCount],
    );

    if (unreadMessagesCount == 0) {
      return const SizedBox();
    }
    return PositionedDirectional(
      top: 10.0.s,
      end: 22.0.s,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.0.s, vertical: 2.0.s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0.s),
          color: context.theme.appColors.attentionRed,
        ),
        constraints: BoxConstraints(
          minWidth: 16.0.s,
        ),
        child: Text(
          '$unreadMessagesCount',
          textAlign: TextAlign.center,
          style: context.theme.appTextThemes.notificationCaption.copyWith(
            color: context.theme.appColors.primaryBackground,
          ),
        ),
      ),
    );
  }
}

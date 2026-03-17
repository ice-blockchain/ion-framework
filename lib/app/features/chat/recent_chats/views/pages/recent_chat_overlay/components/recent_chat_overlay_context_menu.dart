// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item_separator.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/e2ee_delete_event_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_e2ee_message_status_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/manual_unread_conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/request_conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/archive_conversation_message_notification.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_tile/recent_chat_actions.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/block_user_modal/block_user_modal.dart';
import 'package:ion/app/features/user/providers/report_notifier.m.dart';
import 'package:ion/app/features/user_block/optimistic_ui/block_user_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class RecentChatOverlayContextMenu extends ConsumerWidget {
  const RecentChatOverlayContextMenu({
    required this.conversation,
    this.isRequestConversation = false,
    super.key,
  });

  final ConversationListItem conversation;
  final bool isRequestConversation;

  static double heightFor({required bool isRequestConversation}) =>
      isRequestConversation ? 148.0.s : 241.0.s;

  static double get iconSize => 20.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isRequestConversation) {
      return _RequestConversationContextMenu(conversation: conversation);
    }

    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
    final receiverMasterPubkey = conversation.receiverMasterPubkey(currentUserMasterPubkey);

    final isBlocked = receiverMasterPubkey == null
        ? false
        : ref.watch(isBlockedNotifierProvider(receiverMasterPubkey)).valueOrNull;

    final actions = buildRecentChatActions(
      context: context,
      ref: ref,
      conversation: conversation,
    );
    final archiveAction = actions
        .where(
          (a) => a.kind == RecentChatActionKind.archive || a.kind == RecentChatActionKind.unarchive,
        )
        .firstOrNull;
    final primaryActions = actions
        .where(
          (action) =>
              action.kind != RecentChatActionKind.delete &&
              action.kind != RecentChatActionKind.archive &&
              action.kind != RecentChatActionKind.unarchive,
        )
        .toList();
    final deleteAction = actions.firstWhere((action) => action.kind == RecentChatActionKind.delete);

    ref.displayErrors(reportNotifierProvider);

    return SizedBox(
      height: heightFor(isRequestConversation: false),
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: 6.0.s),
        child: OverlayMenuContainer(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0.s),
            child: Column(
              children: [
                ...[
                  ...primaryActions.map(
                    (action) => _RecentChatOverlayActionItem(
                      action: action,
                    ),
                  ),
                  if (archiveAction != null)
                    _ArchiveOverlayActionItem(
                      action: archiveAction,
                      conversation: conversation,
                      ref: ref,
                    ),
                  OverlayMenuItem(
                    label: context.i18n.chat_unread,
                    icon: Assets.svg.chatUnread.icon(
                      size: iconSize,
                      color: context.theme.appColors.quaternaryText,
                    ),
                    onPressed: () {
                      ref
                          .read(manualUnreadConversationsProvider.notifier)
                          .markUnread(conversation.conversationId);
                      Navigator.of(context).pop();
                    },
                    minWidth: 128.0.s,
                    verticalPadding: 12.0.s,
                  ),
                  if (isBlocked != null && currentUserMasterPubkey != null)
                    OverlayMenuItem(
                      label: isBlocked ? context.i18n.button_unblock : context.i18n.button_block,
                      verticalPadding: 12.0.s,
                      icon: Assets.svg.iconPhofileBlockuser.icon(
                        size: iconSize,
                        color: context.theme.appColors.quaternaryText,
                      ),
                      onPressed: () {
                        context.pop();

                        if (receiverMasterPubkey == null) return;

                        if (!isBlocked) {
                          showSimpleBottomSheet<void>(
                            context: context,
                            child: BlockUserModal(pubkey: receiverMasterPubkey),
                          );
                        } else {
                          ref
                              .read(toggleBlockNotifierProvider.notifier)
                              .toggle(receiverMasterPubkey);
                        }
                      },
                    ),
                  _RecentChatOverlayActionItem(
                    action: deleteAction,
                  ),
                ].separated(const OverlayMenuItemSeparator()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchiveOverlayActionItem extends StatelessWidget {
  const _ArchiveOverlayActionItem({
    required this.action,
    required this.conversation,
    required this.ref,
  });

  final RecentChatActionItem action;
  final ConversationListItem conversation;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final iconColor = context.theme.appColors.quaternaryText;

    return OverlayMenuItem(
      label: action.label,
      verticalPadding: 12.0.s,
      minWidth: 128.0.s,
      icon: action.icon.icon(size: RecentChatOverlayContextMenu.iconSize, color: iconColor),
      onPressed: () {
        // Capture values before pop (context may be disposed after)
        final isArchived = action.kind == RecentChatActionKind.unarchive;
        final conversationId = conversation.conversationId;

        if (context.mounted) {
          Navigator.of(context).pop();
        }

        toggleArchiveAndShowMessage(
          context: context,
          ref: ref,
          conversationIds: [conversationId],
          isArchived: isArchived,
          deferToNextFrame: true,
        );
      },
    );
  }
}

class _RecentChatOverlayActionItem extends StatelessWidget {
  const _RecentChatOverlayActionItem({required this.action});

  final RecentChatActionItem action;

  @override
  Widget build(BuildContext context) {
    final iconColor = action.isDestructive
        ? context.theme.appColors.attentionRed
        : context.theme.appColors.quaternaryText;

    return OverlayMenuItem(
      label: action.label,
      labelColor: action.isDestructive ? context.theme.appColors.attentionRed : null,
      verticalPadding: 12.0.s,
      minWidth: 128.0.s,
      icon: action.icon.icon(size: RecentChatOverlayContextMenu.iconSize, color: iconColor),
      onPressed: () async {
        final shouldClose = await action.onSelected();
        if (shouldClose && context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}

class _RequestConversationContextMenu extends ConsumerWidget {
  const _RequestConversationContextMenu({required this.conversation});

  final ConversationListItem conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteConversationIds = List<String>.unmodifiable([conversation.conversationId]);
    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
    final receiverMasterPubkey = conversation.receiverMasterPubkey(currentUserMasterPubkey);
    final isBlocked = receiverMasterPubkey == null
        ? false
        : ref.watch(isBlockedNotifierProvider(receiverMasterPubkey)).valueOrNull;

    ref.displayErrors(reportNotifierProvider);

    Future<void> popRequestsPageIfNeeded({required bool shouldPopToChats}) async {
      if (!shouldPopToChats) {
        return;
      }

      final chatNavigator = bottomBarNavigatorKey.currentState;
      if (chatNavigator != null && chatNavigator.canPop()) {
        await chatNavigator.maybePop();
      }
    }

    Future<void> onApprove() async {
      final requestsBeforeApprove = ref.read(requestConversationsProvider).valueOrNull;
      final shouldPopToChats = (requestsBeforeApprove?.length ?? 0) <= 1;

      final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);
      if (currentUserMasterPubkey == null) {
        return;
      }

      final allMessages = await ref
          .read(conversationMessageDaoProvider)
          .getMessages(conversation.conversationId)
          .first;

      final inboundMessages =
          allMessages.where((message) => message.masterPubkey != currentUserMasterPubkey).toList();

      if (inboundMessages.isEmpty) {
        return;
      }

      final statusService = await ref.read(sendE2eeMessageStatusServiceProvider.future);
      final messageDataDao = ref.read(conversationMessageDataDaoProvider);

      for (final message in inboundMessages) {
        final eventReference =
            ReplaceablePrivateDirectMessageEntity.fromEventMessage(message).toEventReference();

        final currentStatus = await messageDataDao.checkMessageStatus(
          masterPubkey: currentUserMasterPubkey,
          eventReference: eventReference,
        );

        if (currentStatus == null || currentStatus.index < MessageDeliveryStatus.received.index) {
          await statusService.sendMessageStatus(
            messageEventMessage: message,
            status: MessageDeliveryStatus.received,
          );
        }
      }

      await statusService.sendMessageStatus(
        messageEventMessage: inboundMessages.first,
        status: MessageDeliveryStatus.read,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        await popRequestsPageIfNeeded(shouldPopToChats: shouldPopToChats);
      }
    }

    Future<void> onDelete() async {
      final requestsBeforeDelete = ref.read(requestConversationsProvider).valueOrNull;
      final shouldPopToChats = (requestsBeforeDelete?.length ?? 0) <= 1;

      await ref.read(
        e2eeDeleteConversationProvider(conversationIds: deleteConversationIds).future,
      );

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pop();
      await popRequestsPageIfNeeded(shouldPopToChats: shouldPopToChats);
    }

    return SizedBox(
      height: RecentChatOverlayContextMenu.heightFor(isRequestConversation: true),
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: 6.0.s),
        child: OverlayMenuContainer(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0.s),
            child: Column(
              children: [
                OverlayMenuItem(
                  label: context.i18n.button_approve,
                  icon: Assets.svg.iconChatApprove.icon(
                    size: RecentChatOverlayContextMenu.iconSize,
                    color: context.theme.appColors.primaryAccent,
                  ),
                  verticalPadding: 12.0.s,
                  onPressed: onApprove,
                ),
                const OverlayMenuItemSeparator(),
                if (isBlocked != null)
                  OverlayMenuItem(
                    label: isBlocked ? context.i18n.button_unblock : context.i18n.button_block,
                    verticalPadding: 12.0.s,
                    icon: Assets.svg.iconPhofileBlockuser.icon(
                      size: RecentChatOverlayContextMenu.iconSize,
                      color: context.theme.appColors.quaternaryText,
                    ),
                    onPressed: () async {
                      if (receiverMasterPubkey == null) {
                        return;
                      }

                      if (!isBlocked) {
                        final requestsBeforeBlock =
                            ref.read(requestConversationsProvider).valueOrNull;
                        final shouldPopToChats = (requestsBeforeBlock?.length ?? 0) <= 1;

                        context.pop();

                        final blocked = await showSimpleBottomSheet<bool>(
                              context: context,
                              child: BlockUserModal(pubkey: receiverMasterPubkey),
                            ) ??
                            false;

                        if (blocked && context.mounted) {
                          await popRequestsPageIfNeeded(shouldPopToChats: shouldPopToChats);
                        }
                      } else {
                        context.pop();
                        unawaited(
                          ref
                              .read(toggleBlockNotifierProvider.notifier)
                              .toggle(receiverMasterPubkey),
                        );
                      }
                    },
                  ),
                if (isBlocked != null) const OverlayMenuItemSeparator(),
                OverlayMenuItem(
                  label: context.i18n.button_delete,
                  labelColor: context.theme.appColors.attentionRed,
                  icon: Assets.svg.iconBlockDelete.icon(
                    size: RecentChatOverlayContextMenu.iconSize,
                    color: context.theme.appColors.attentionRed,
                  ),
                  verticalPadding: 12.0.s,
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

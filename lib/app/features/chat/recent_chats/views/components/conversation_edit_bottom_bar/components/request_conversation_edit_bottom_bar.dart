// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/e2ee_delete_event_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_e2ee_message_status_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/conversations_edit_mode_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/request_conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_conversations_ids_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class RequestConversationEditBottomBar extends HookConsumerWidget {
  const RequestConversationEditBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedConversations = ref.watch(selectedConversationsProvider);
    final requestConversations = ref.watch(requestConversationsProvider).valueOrNull ?? const [];
    final isProcessing = useState(false);

    final selectedRequestConversations = selectedConversations
        .where(
          (selected) => requestConversations.any(
            (requestConversation) => requestConversation.conversationId == selected.conversationId,
          ),
        )
        .toList();

    final selectedCount = selectedRequestConversations.length;
    final conversationsToManage =
        selectedCount == 0 ? requestConversations : selectedRequestConversations;
    final usePluralActionLabels = selectedCount != 1;
    final approveLabel =
        usePluralActionLabels ? context.i18n.button_approve_all : context.i18n.button_approve;
    final deleteLabel =
        usePluralActionLabels ? context.i18n.button_delete_all : context.i18n.button_delete;

    Future<void> onApproveTap() async {
      if (conversationsToManage.isEmpty || isProcessing.value) {
        return;
      }

      isProcessing.value = true;
      try {
        await _approveConversations(conversationsToManage, ref);
      } finally {
        isProcessing.value = false;
      }
    }

    Future<void> onDeleteTap() async {
      if (conversationsToManage.isEmpty || isProcessing.value) {
        return;
      }

      isProcessing.value = true;
      try {
        await _rejectConversations(conversationsToManage, ref);
      } finally {
        isProcessing.value = false;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _RequestActionButton(
            label: approveLabel,
            iconPath: Assets.svg.iconChatApprove,
            color: context.theme.appColors.primaryAccent,
            enabled: conversationsToManage.isNotEmpty,
            onTap: onApproveTap,
          ),
        ),
        SizedBox(width: 8.0.s),
        Expanded(
          child: _RequestActionButton(
            label: deleteLabel,
            iconPath: Assets.svg.iconBlockDelete,
            color: context.theme.appColors.attentionRed,
            enabled: conversationsToManage.isNotEmpty,
            onTap: onDeleteTap,
          ),
        ),
      ],
    );
  }

  Future<void> _approveConversations(
    List<ConversationListItem> conversations,
    WidgetRef ref,
  ) async {
    final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);

    if (currentUserMasterPubkey == null || conversations.isEmpty) {
      return;
    }

    final conversationMessageDao = ref.read(conversationMessageDaoProvider);
    final messageDataDao = ref.read(conversationMessageDataDaoProvider);
    final statusService = await ref.read(sendE2eeMessageStatusServiceProvider.future);

    for (final conversation in conversations) {
      final allMessages =
          await conversationMessageDao.getMessages(conversation.conversationId).first;
      final inboundMessages =
          allMessages.where((message) => message.masterPubkey != currentUserMasterPubkey).toList();

      if (inboundMessages.isEmpty) {
        continue;
      }

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
    }

    _clearEditMode(ref);
  }

  Future<void> _rejectConversations(
    List<ConversationListItem> conversations,
    WidgetRef ref,
  ) async {
    final conversationIds =
        conversations.map((conversation) => conversation.conversationId).toList();

    if (conversationIds.isEmpty) {
      return;
    }

    await ref.read(e2eeDeleteConversationProvider(conversationIds: conversationIds).future);

    _clearEditMode(ref);
  }

  void _clearEditMode(WidgetRef ref) {
    ref.read(conversationsEditModeProvider.notifier).editMode = false;
    ref.read(selectedConversationsProvider.notifier).clear();
  }
}

class _RequestActionButton extends StatelessWidget {
  const _RequestActionButton({
    required this.label,
    required this.iconPath,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final actionColor = enabled ? color : context.theme.appColors.tertiaryText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconPath.icon(
            color: actionColor,
            size: 20.0.s,
          ),
          SizedBox(width: 4.0.s),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.appTextThemes.body2.copyWith(
                color: actionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/e2ee_delete_event_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_e2ee_message_status_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/generated/assets.gen.dart';

class RequestPendingUserBar extends HookConsumerWidget {
  const RequestPendingUserBar({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isApproving = useState(false);
    final deleteConversationIds = List<String>.unmodifiable([conversationId]);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    Future<void> onApproveTap() async {
      if (isApproving.value) {
        return;
      }

      final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);
      if (currentUserMasterPubkey == null) {
        return;
      }

      isApproving.value = true;

      try {
        final allMessages =
            await ref.read(conversationMessageDaoProvider).getMessages(conversationId).first;

        final inboundMessages = allMessages
            .where((message) => message.masterPubkey != currentUserMasterPubkey)
            .toList();

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

        if (context.mounted && context.canPop()) {
          context.pop();
        }
      } finally {
        isApproving.value = false;
      }
    }

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16.0.s, 8.0.s, 16.0.s, bottomPadding + 8.0.s),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: isApproving.value
                  ? null
                  : () {
                      ref.read(
                        e2eeDeleteConversationProvider(conversationIds: deleteConversationIds),
                      );
                      context.pop();
                    },
              style: TextButton.styleFrom(
                minimumSize: Size(0, 44.0.s),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Assets.svg.iconBlockDelete.icon(
                    size: 20.0.s,
                    color: context.theme.appColors.attentionRed,
                  ),
                  SizedBox(width: 6.0.s),
                  Text(
                    context.i18n.button_delete,
                    style: context.theme.appTextThemes.subtitle3
                        .copyWith(color: context.theme.appColors.attentionRed),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.0.s),
          Expanded(
            child: TextButton(
              onPressed: isApproving.value ? null : onApproveTap,
              style: TextButton.styleFrom(
                minimumSize: Size(0, 44.0.s),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Assets.svg.iconChatApprove.icon(
                    size: 20.0.s,
                    color: context.theme.appColors.primaryAccent,
                  ),
                  SizedBox(width: 6.0.s),
                  Text(
                    context.i18n.button_approve,
                    style: context.theme.appTextThemes.subtitle3
                        .copyWith(color: context.theme.appColors.primaryAccent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

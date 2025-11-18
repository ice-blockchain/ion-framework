// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/components/messaging_header/one_to_one_messaging_header.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/e2ee/views/components/e2ee_conversation_empty_view.dart';
import 'package:ion/app/features/chat/e2ee/views/components/one_to_one_messages_list.dart';
import 'package:ion/app/features/chat/model/participiant_keys.f.dart';
import 'package:ion/app/features/chat/providers/conversation_messages_provider.r.dart';
import 'package:ion/app/features/chat/providers/exist_chat_conversation_id_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_edit_message_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_reply_message_provider.r.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/chat_input_bar.dart';
import 'package:ion/app/features/chat/views/components/message_items/edit_message_info/edit_message_info.dart';
import 'package:ion/app/features/chat/views/components/message_items/replied_message_info/replied_message_info.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/services/local_notifications/local_notifications.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

class OneToOneMessagesPage extends HookConsumerWidget {
  const OneToOneMessagesPage({
    required this.receiverMasterPubkey,
    super.key,
  });

  final String receiverMasterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider)!;
    final conversationId = ref
        .watch(
          existChatConversationIdProvider(
            ParticipantKeys(keys: [receiverMasterPubkey, currentUserMasterPubkey].sorted()),
          ),
        )
        .valueOrNull;

    useOnInit(
      () async {
        if (conversationId == null) {
          return;
        }

        final localNotificationsService = await ref.read(localNotificationsServiceProvider.future);
        await localNotificationsService.cancelByGroupKey(conversationId);

        await ref.read(userMetadataProvider(receiverMasterPubkey, cache: false).future);
      },
      [conversationId],
    );

    final onSubmitted = useCallback(
      ({String? content, List<MediaFile>? mediaFiles}) async {
        final currentPubkey = ref.read(currentPubkeySelectorProvider);
        if (currentPubkey == null) {
          throw UserMasterPubkeyNotFoundException();
        }

        final repliedMessage = ref.read(selectedReplyMessageProvider);
        final editedMessage = ref.read(selectedEditMessageProvider);

        ref.read(selectedEditMessageProvider.notifier).clear();
        ref.read(selectedReplyMessageProvider.notifier).clear();

        await ref.read(sendE2eeChatMessageServiceProvider).sendMessage(
          content: content ?? '',
          mediaFiles: mediaFiles ?? [],
          conversationId: conversationId!,
          editedMessage: editedMessage?.eventMessage,
          repliedMessage: repliedMessage?.eventMessage,
          participantsMasterPubkeys: [receiverMasterPubkey, currentPubkey],
        );
        for (var i = 0; i < 10000; i++) {
          await ref.read(sendE2eeChatMessageServiceProvider).sendMessage(
            content: 'Message $i',
            mediaFiles: mediaFiles ?? [],
            conversationId: conversationId,
            participantsMasterPubkeys: [receiverMasterPubkey, currentPubkey],
          );
        }
      },
      [receiverMasterPubkey, conversationId],
    );

    return Scaffold(
      backgroundColor: context.theme.appColors.secondaryBackground,
      body: SafeArea(
        bottom: false,
        child: ListCachedObjectsWrapper(
          child: Column(
            children: [
              _Header(
                receiverMasterPubkey: receiverMasterPubkey,
                conversationId: conversationId ?? '',
              ),
              Expanded(child: _MessagesList(conversationId: conversationId)),
              const EditMessageInfo(),
              const RepliedMessageInfo(),
              ChatInputBar(
                onSubmitted: onSubmitted,
                receiverMasterPubkey: receiverMasterPubkey,
                conversationId: conversationId ?? '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends HookConsumerWidget {
  const _Header({
    required this.conversationId,
    required this.receiverMasterPubkey,
  });

  final String receiverMasterPubkey;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OneToOneMessagingHeader(
      conversationId: conversationId,
      receiverMasterPubkey: receiverMasterPubkey,
    );
  }
}

class _MessagesList extends ConsumerWidget {
  const _MessagesList({
    required this.conversationId,
  });

  final String? conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (conversationId == null) {
      return const _MessageListEmptyView();
    }

    final asyncMessages = ref.watch(conversationMessagesProvider(conversationId!));

    return asyncMessages.when(
      data: (messages) {
        if (messages.isEmpty) {
          return const E2eeConversationEmptyView();
        }
        return OneToOneMessageList(messages, conversationId: conversationId!);
      },
      loading: () => const _MessageListEmptyView(),
      error: (err, stack) {
        return const _MessageListEmptyView();
      },
    );
  }
}

class _MessageListEmptyView extends StatelessWidget {
  const _MessageListEmptyView();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.theme.appColors.primaryBackground,
      child: const SizedBox.expand(),
    );
  }
}

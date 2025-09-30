// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/components/messaging_header/one_to_one_messaging_header.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/e2ee/views/components/e2ee_conversation_empty_view.dart';
import 'package:ion/app/features/chat/e2ee/views/components/e2ee_conversation_loading_view.dart';
import 'package:ion/app/features/chat/e2ee/views/components/one_to_one_messages_list.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/conversation_messages_provider.r.dart';
import 'package:ion/app/features/chat/providers/exist_chat_conversation_id_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_edit_message_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_reply_message_provider.r.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/chat_input_bar.dart';
import 'package:ion/app/features/chat/views/components/message_items/edit_message_info/edit_message_info.dart';
import 'package:ion/app/features/chat/views/components/message_items/replied_message_info/replied_message_info.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/user_profile/providers/user_profile_sync_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/services/uuid/generate_conversation_id.dart';

class OneToOneMessagesPage extends HookConsumerWidget {
  const OneToOneMessagesPage({
    required this.receiverMasterPubkey,
    super.key,
  });

  final String receiverMasterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = useState<String?>(null);

    useOnInit(
      () async {
        unawaited(
          ref
              .read(userProfileSyncProvider.notifier)
              .syncUserProfile(masterPubkeys: {receiverMasterPubkey}),
        );

        final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);

        if (currentUserMasterPubkey == null) {
          throw UserMasterPubkeyNotFoundException();
        }

        final participantsMasterPubkeys = [
          receiverMasterPubkey,
          currentUserMasterPubkey,
        ];

        final existingConversationId = await ref.read(
          existChatConversationIdProvider(participantsMasterPubkeys).future,
        );

        conversationId.value = existingConversationId ??
            generateConversationId(
              conversationType: ConversationType.oneToOne,
              receiverMasterPubkeys: [receiverMasterPubkey, currentUserMasterPubkey],
            );
      },
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
          conversationId: conversationId.value!,
          editedMessage: editedMessage?.eventMessage,
          repliedMessage: repliedMessage?.eventMessage,
          participantsMasterPubkeys: [receiverMasterPubkey, currentPubkey],
        );
      },
      [receiverMasterPubkey],
    );

    return Scaffold(
      backgroundColor: context.theme.appColors.secondaryBackground,
      body: SafeArea(
        child: ListCachedObjectsWrapper(
          child: Column(
            children: [
              _Header(
                receiverMasterPubkey: receiverMasterPubkey,
                conversationId: conversationId.value ?? '',
              ),
              _MessagesList(conversationId: conversationId.value),
              const EditMessageInfo(),
              const RepliedMessageInfo(),
              ChatInputBar(
                onSubmitted: onSubmitted,
                receiverMasterPubkey: receiverMasterPubkey,
                conversationId: conversationId.value,
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
  const _MessagesList({required this.conversationId});

  final String? conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (conversationId == null) {
      return Expanded(
        child: ColoredBox(
          color: context.theme.appColors.primaryBackground,
        ),
      );
    }

    final messages =
        ref.watch(conversationMessagesProvider(conversationId!, ConversationType.oneToOne));

    return Expanded(
      child: messages.maybeWhen(
        data: (messages) {
          if (messages.isEmpty) {
            return const E2eeConversationEmptyView();
          }
          return OneToOneMessageList(messages);
        },
        loading: () => const E2eeConversationLoadingView(),
        orElse: () {
          return ColoredBox(
            color: context.theme.appColors.primaryBackground,
          );
        },
      ),
    );
  }
}

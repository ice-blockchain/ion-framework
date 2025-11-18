// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/view/components/community_member_count_tile.dart';
import 'package:ion/app/features/chat/components/messaging_header/messaging_header.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/e2ee/views/components/e2ee_conversation_empty_view.dart';
import 'package:ion/app/features/chat/e2ee/views/components/one_to_one_messages_list.dart';
import 'package:ion/app/features/chat/providers/conversation_messages_provider.r.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/chat_input_bar.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/services/media_service/media_encryption_service.m.dart';

class GroupMessagesPage extends HookConsumerWidget {
  const GroupMessagesPage({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref
        .watch(
          conversationMessagesProvider(conversationId),
        )
        .valueOrNull;

    final lastMessage = messages?.lastOrNull;

    if (lastMessage == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: context.theme.appColors.secondaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            _Header(lastMessage: lastMessage),
            _MessagesList(conversationId: conversationId),
            ChatInputBar(
              receiverMasterPubkey: '', //TODO: set when groups are impl
              conversationId: conversationId,
              onSubmitted: ({content, mediaFiles}) async {
                final currentPubkey = ref.read(currentPubkeySelectorProvider);
                if (currentPubkey == null) {
                  throw UserMasterPubkeyNotFoundException();
                }

                final privateMessageEntity =
                    ReplaceablePrivateDirectMessageData.fromEventMessage(lastMessage);

                final conversationMessageManagementService =
                    ref.read(sendE2eeChatMessageServiceProvider);

                final groupImageTag = lastMessage.tags.firstWhereOrNull((e) => e.first == 'imeta');

                await conversationMessageManagementService.sendMessage(
                  conversationId: conversationId,
                  content: content ?? '',
                  mediaFiles: mediaFiles ?? [],
                  groupImageTag: groupImageTag,
                  subject: privateMessageEntity.groupSubject?.value,
                  participantsMasterPubkeys:
                      privateMessageEntity.relatedPubkeys?.map((e) => e.value).toList() ?? [],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends HookConsumerWidget {
  const _Header({required this.lastMessage});

  final EventMessage lastMessage;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ReplaceablePrivateDirectMessageData.fromEventMessage(lastMessage);
    final groupImageFile = useFuture(
      ref.watch(mediaEncryptionServiceProvider).getEncryptedMedia(
            entity.primaryMedia!,
            authorPubkey: lastMessage.masterPubkey,
          ),
    ).data;

    return MessagingHeader(
      conversationId: '', //TODO: set when groups are impl
      imageWidget: groupImageFile != null ? Image.file(groupImageFile) : null,
      name: entity.groupSubject?.value ?? '',
      subtitle: MemberCountTile(count: entity.relatedPubkeys?.length ?? 0),
    );
  }
}

class _MessagesList extends ConsumerWidget {
  const _MessagesList({required this.conversationId});

  final String conversationId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(conversationMessagesProvider(conversationId));
    return Expanded(
      child: messages.maybeWhen(
        data: (messages) {
          if (messages.isEmpty) {
            return const E2eeConversationEmptyView();
          }
          return OneToOneMessageList(messages, conversationId: conversationId);
        },
        orElse: () => const SizedBox.expand(),
      ),
    );
  }
}

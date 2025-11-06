// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/view/components/community_member_count_tile.dart';
import 'package:ion/app/features/chat/components/messaging_header/messaging_header.dart';
import 'package:ion/app/features/chat/e2ee/model/group_metadata.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/encrypted_group_metadata_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/e2ee/views/components/e2ee_conversation_empty_view.dart';
import 'package:ion/app/features/chat/e2ee/views/components/one_to_one_messages_list.dart';
import 'package:ion/app/features/chat/e2ee/views/pages/group_admin_page/components/group_avatar.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/conversation_messages_provider.r.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/chat_input_bar.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class GroupMessagesPage extends HookConsumerWidget {
  const GroupMessagesPage({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupMetadata = ref.watch(encryptedGroupMetadataProvider(conversationId)).valueOrNull;

    if (groupMetadata == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: context.theme.appColors.secondaryBackground,
      body: SafeArea(
        child: ListCachedObjectsWrapper(
          child: Column(
            children: [
              _Header(conversationId: conversationId, groupMetadata: groupMetadata),
              _MessagesList(conversationId: conversationId),
              ChatInputBar(
                receiverMasterPubkey: '', //TODO: set when groups are impl
                conversationId: conversationId,
                onSubmitted: ({content, mediaFiles}) async {
                  final currentPubkey = ref.read(currentPubkeySelectorProvider);
                  if (currentPubkey == null) {
                    throw UserMasterPubkeyNotFoundException();
                  }

                  final conversationMessageManagementService =
                      ref.read(sendE2eeChatMessageServiceProvider);

                  await conversationMessageManagementService.sendMessage(
                    conversationId: conversationId,
                    content: content ?? '',
                    mediaFiles: mediaFiles ?? [],
                    participantsMasterPubkeys:
                        groupMetadata.members.map((member) => member.masterPubkey).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.conversationId,
    required this.groupMetadata,
  });

  final String conversationId;
  final GroupMetadata groupMetadata;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MessagingHeader(
      conversationId: '',
      imageWidget: GroupAvatar(
        avatar: groupMetadata.avatar,
        size: 40.0.s,
        borderRadius: BorderRadius.circular(12.0.s),
      ),
      name: groupMetadata.name,
      subtitle: MemberCountTile(count: groupMetadata.members.length),
      onTap: () {
        GroupAdminPageRoute(conversationId: conversationId).push<void>(context);
      },
    );
  }
}

class _MessagesList extends ConsumerWidget {
  const _MessagesList({required this.conversationId});

  final String conversationId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages =
        ref.watch(conversationMessagesProvider(conversationId, ConversationType.groupEncrypted));
    return Expanded(
      child: messages.maybeWhen(
        data: (messages) {
          if (messages.isEmpty) {
            return const E2eeConversationEmptyView();
          }
          return OneToOneMessageList(messages);
        },
        orElse: () => const SizedBox.expand(),
      ),
    );
  }
}

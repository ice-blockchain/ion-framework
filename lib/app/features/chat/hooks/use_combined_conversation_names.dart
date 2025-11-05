// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/providers/community_metadata_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';

String? useCombinedConversationNames(
  List<ConversationListItem> conversations,
  WidgetRef ref,
) {
  final future = useMemoized(
    () async {
      final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);

      final names = <String>[];
      for (final conversation in conversations) {
        if (conversation.type == ConversationType.direct) {
          final latestMessageEntity =
              EncryptedDirectMessageData.fromEventMessage(conversation.latestMessage!);

          final receiver = latestMessageEntity.relatedPubkeys!
              .firstWhere((pubkey) => pubkey.value != currentUserMasterPubkey)
              .value;

          final userPreviewData = await ref.read(userPreviewDataProvider(receiver).future);
          if (userPreviewData != null) {
            names.add(userPreviewData.data.trimmedDisplayName);
          }
        } else if (conversation.type == ConversationType.community) {
          final community =
              await ref.read(communityMetadataProvider(conversation.conversationId).future);
          names.add(community.data.name);
        } else {
          final latestMessageEntity =
              EncryptedDirectMessageData.fromEventMessage(conversation.latestMessage!);
          names.add(latestMessageEntity.groupSubject?.value ?? '');
        }
      }
      return names.join(', ');
    },
    conversations,
  );

  final snapshot = useFuture(future);
  return snapshot.data;
}

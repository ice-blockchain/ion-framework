// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/feed/data/models/bookmarks/bookmarks_set.f.dart';
import 'package:ion/app/features/feed/providers/bookmarks_notifier.r.dart';
import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart';
import 'package:ion/app/services/ion_connect/encrypted_message_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'archived_conversations_provider.r.g.dart';

@riverpod
Future<List<String>> archivedConversations(Ref ref) async {
  final archivedConversationBookmarksSetData =
      await ref.watch(currentUserChatBookmarksDataProvider.future) ??
          BookmarksSetData(
            type: BookmarksSetType.chats.dTagName,
            eventReferences: [],
          );

  final currentUserPubkey = ref.read(currentPubkeySelectorProvider);
  final encryptedMessageService = await ref.watch(encryptedMessageServiceProvider.future);

  if (currentUserPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final content = archivedConversationBookmarksSetData.content;

  final decryptedContent = content.isNotEmpty
      ? await encryptedMessageService.decryptMessage(
          archivedConversationBookmarksSetData.content,
        )
      : archivedConversationBookmarksSetData.content;

  final encryptedConversationCommunityIds = decryptedContent.isNotEmpty
      ? (jsonDecode(decryptedContent) as List<dynamic>)
          .map(
            (e) => ConversationIdentifier.fromTag(
              (e as List<dynamic>).map((s) => s.toString()).toList(),
            ).value,
          )
          .toList()
      : null;

  final archivedConversations = [
    ...archivedConversationBookmarksSetData.communitiesIds,
    if (encryptedConversationCommunityIds != null) ...encryptedConversationCommunityIds,
  ];

  await ref.watch(conversationDaoProvider).updateArchivedConversations(archivedConversations);

  return archivedConversations;
}

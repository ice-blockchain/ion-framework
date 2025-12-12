// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/user_archive/model/database/user_archive_database.m.dart';
import 'package:ion/app/features/user_archive/model/entities/user_archive_entity.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'conversations_provider.r.g.dart';

@riverpod
Stream<List<ConversationListItem>> conversations(Ref ref) {
  return ref.watch(conversationDaoProvider).watch();
}

@riverpod
Stream<List<ConversationListItem>> notArchivedConversations(Ref ref) {
  // Get user archive stream directly from DAO
  final userArchiveEventDao = ref.watch(userArchiveEventDaoProvider);
  final archivedIdsStream = userArchiveEventDao.watchLatestArchiveEvent().map(
    (event) {
      final entity = event == null ? null : UserArchiveEntity.fromEventMessage(event);
      return entity?.data.archivedConversations ?? <String>[];
    },
  );

  // Get conversations stream directly from DAO
  final conversationsStream = ref.watch(conversationDaoProvider).watch();

  // Combine both streams using Rx.combineLatest2
  return Rx.combineLatest2<List<ConversationListItem>, List<String>, List<ConversationListItem>>(
    conversationsStream,
    archivedIdsStream,
    (conversations, archivedIds) {
      return conversations
          .where((conversation) => !archivedIds.contains(conversation.conversationId))
          .toList();
    },
  );
}

@riverpod
Stream<List<ConversationListItem>> archivedConversations(Ref ref) {
  // Get user archive stream directly from DAO
  final userArchiveEventDao = ref.watch(userArchiveEventDaoProvider);
  final archivedIdsStream = userArchiveEventDao.watchLatestArchiveEvent().map(
    (event) {
      final entity = event == null ? null : UserArchiveEntity.fromEventMessage(event);
      return entity?.data.archivedConversations ?? <String>[];
    },
  );

  // Get conversations stream directly from DAO
  final conversationsStream = ref.watch(conversationDaoProvider).watch();

  // Combine both streams using Rx.combineLatest2
  return Rx.combineLatest2<List<ConversationListItem>, List<String>, List<ConversationListItem>>(
    conversationsStream,
    archivedIdsStream,
    (conversations, archivedIds) {
      return conversations
          .where((conversation) => archivedIds.contains(conversation.conversationId))
          .toList();
    },
  );
}

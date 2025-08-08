// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversations_provider.r.g.dart';

@riverpod
Stream<List<ConversationListItem>> conversations(Ref ref) {
  return ref.watch(conversationDaoProvider).watch();
}

@riverpod
Future<List<ConversationListItem>> archivedConversations(
  Ref ref,
) {
  return ref.watch(conversationsProvider.selectAsync((t) => t.where((c) => c.isArchived).toList()));
}

// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/conversation_request_approval_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/user_archive/model/database/user_archive_database.m.dart';
import 'package:ion/app/features/user_archive/model/entities/user_archive_entity.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'request_conversations_provider.r.g.dart';

@riverpod
Stream<List<ConversationListItem>> requestConversations(Ref ref) {
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentUserMasterPubkey == null) {
    return Stream.value(const <ConversationListItem>[]);
  }

  final conversationsStream = ref.watch(conversationDaoProvider).watch();
  final archivedConversationIdsStream =
      ref.watch(userArchiveEventDaoProvider).watchLatestArchiveEvent().map(
    (event) {
      final entity = event == null ? null : UserArchiveEntity.fromEventMessage(event);
      return entity?.data.archivedConversations ?? <String>[];
    },
  );

  return Rx.combineLatest2<List<ConversationListItem>, List<String>, List<ConversationListItem>>(
    conversationsStream,
    archivedConversationIdsStream,
    (conversations, archivedConversationIds) {
      final archivedConversationIdsSet = archivedConversationIds.toSet();

      return conversations.where((ConversationListItem conversation) {
        if (archivedConversationIdsSet.contains(conversation.conversationId)) {
          return false;
        }

        if (conversation.type != ConversationType.oneToOne || conversation.latestMessage == null) {
          return false;
        }

        // Request folder contains inbound chats only.
        if (conversation.latestMessage!.masterPubkey == currentUserMasterPubkey) {
          return false;
        }

        return true;
      }).toList(growable: false);
    },
  ).switchMap((candidates) {
    if (candidates.isEmpty) {
      return Stream.value(const <ConversationListItem>[]);
    }

    final approvalStreams = candidates
        .map((conversation) {
          final senderMasterPubkey = conversation.receiverMasterPubkey(currentUserMasterPubkey);
          if (senderMasterPubkey == null) {
            return null;
          }

          return conversationRequestApproval(
            ref,
            conversation.conversationId,
            senderMasterPubkey: senderMasterPubkey,
            isIncomingContext: true,
          ).map((approval) => (conversation, approval));
        })
        .nonNulls
        .toList(growable: false);

    if (approvalStreams.isEmpty) {
      return Stream.value(const <ConversationListItem>[]);
    }

    return Rx.combineLatestList<(ConversationListItem, ConversationRequestApprovalState)>(
      approvalStreams,
    ).map(
      (items) => items
          .where((item) => item.$2 == ConversationRequestApprovalState.pending)
          .map((item) => item.$1)
          .toList(growable: false),
    );
  }).distinct(_sameConversationIds);
}

bool _sameConversationIds(List<ConversationListItem> previous, List<ConversationListItem> next) {
  if (identical(previous, next)) {
    return true;
  }

  if (previous.length != next.length) {
    return false;
  }

  for (var i = 0; i < previous.length; i++) {
    if (previous[i].conversationId != next[i].conversationId) {
      return false;
    }
  }

  return true;
}

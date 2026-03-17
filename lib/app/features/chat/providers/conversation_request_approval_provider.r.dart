// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stream_transform/stream_transform.dart';

part 'conversation_request_approval_provider.r.g.dart';

enum ConversationRequestApprovalState {
  pending,
  approved,
}

const _conversationRequestApprovalCacheDuration = Duration(minutes: 5);

@riverpod
Stream<ConversationRequestApprovalState> conversationRequestApproval(
  Ref ref,
  String conversationId, {
  required String senderMasterPubkey,
  bool isIncomingContext = false,
}) {
  ref.cacheFor(_conversationRequestApprovalCacheDuration);

  final isFollowingSender = ref.watch(isCurrentUserFollowingSelectorProvider(senderMasterPubkey));

  if (isFollowingSender) {
    return Stream.value(ConversationRequestApprovalState.approved);
  }

  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentUserMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final messageDataDao = ref.watch(conversationMessageDataDaoProvider);

  return messageDataDao
      .watchHasVisibleMessages(conversationId: conversationId)
      .switchMap((hasVisibleMessages) {
    if (!hasVisibleMessages) {
      return Stream.value(
        isIncomingContext
            ? ConversationRequestApprovalState.pending
            : ConversationRequestApprovalState.approved,
      );
    }

    return messageDataDao
        .watchHasInboundVisibleMessages(
      conversationId: conversationId,
      currentUserMasterPubkey: currentUserMasterPubkey,
    )
        .switchMap((hasInboundVisibleMessages) {
      if (!hasInboundVisibleMessages) {
        return Stream.value(ConversationRequestApprovalState.approved);
      }

      return messageDataDao
          .watchConversationStatusAtLeast(
            conversationId: conversationId,
            masterPubkey: currentUserMasterPubkey,
            status: MessageDeliveryStatus.received,
          )
          .map(
            (hasConversationReceivedStatus) => hasConversationReceivedStatus
                ? ConversationRequestApprovalState.approved
                : ConversationRequestApprovalState.pending,
          );
    });
  }).distinct();
}

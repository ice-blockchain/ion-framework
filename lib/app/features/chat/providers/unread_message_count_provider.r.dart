// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/muted_conversations_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unread_message_count_provider.r.g.dart';

@riverpod
Stream<int> getUnreadMessagesCount(Ref ref, String conversationId) async* {
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentUserMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  yield* ref.watch(conversationMessageDaoProvider).getUnreadMessagesCount(
        conversationId: conversationId,
        currentUserMasterPubkey: currentUserMasterPubkey,
      );
}

@riverpod
Stream<int> getAllUnreadMessagesCountInArchive(Ref ref) async* {
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentUserMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  yield* ref
      .watch(conversationMessageDaoProvider)
      .getAllUnreadMessagesCountInArchive(currentUserMasterPubkey);
}

@riverpod
Stream<int> getAllUnreadMessagesCount(Ref ref) async* {
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentUserMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final mutedConversationIds = await ref.watch(mutedConversationsProvider.future);

  yield* ref
      .watch(conversationMessageDaoProvider)
      .getAllUnreadMessagesCount(currentUserMasterPubkey, mutedConversationIds);
}

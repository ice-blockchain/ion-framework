// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_messages_provider.r.g.dart';

@riverpod
class ConversationMessages extends _$ConversationMessages {
  @override
  Stream<Map<DateTime, List<EventMessage>>> build(String conversationId, ConversationType type) {
    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

    if (currentUserMasterPubkey == null) {
      return const Stream.empty();
    }

    return ref.watch(conversationMessageDaoProvider).getMessages(conversationId);
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/participiant_keys.f.dart';
import 'package:ion/app/services/uuid/generate_conversation_id.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exist_chat_conversation_id_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<String> existChatConversationId(Ref ref, ParticipantKeys participantKeys) async {
  final conversationId =
      await ref.watch(conversationDaoProvider).getExistingConversationId(participantKeys.keys);
  if (conversationId == null) {
    return generateConversationId(
      conversationType: ConversationType.oneToOne,
      receiverMasterPubkeys: participantKeys.keys,
    );
  }
  return conversationId;
}

@riverpod
Future<bool> checkIfConversationExists(Ref ref, String conversationId) async {
  return ref.watch(conversationDaoProvider).checkIfConversationExists(conversationId);
}

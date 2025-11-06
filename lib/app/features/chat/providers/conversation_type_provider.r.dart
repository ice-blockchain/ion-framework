// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_type_provider.r.g.dart';

@riverpod
Future<ConversationType> conversationType(
  Ref ref,
  String? conversationId,
  String? receiverPubKey,
) async {
  if (receiverPubKey != null) {
    return ConversationType.directEncrypted;
  }

  if (conversationId == null) {
    throw ConversationTypeNotFoundException();
  }

  final conversationType =
      await ref.watch(conversationDaoProvider).getConversationType(conversationId);

  if (conversationType == null) {
    throw ConversationTypeNotFoundException();
  }

  return conversationType;
}

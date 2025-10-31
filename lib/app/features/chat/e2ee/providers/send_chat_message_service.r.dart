// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/exist_chat_conversation_id_provider.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/services/uuid/generate_conversation_id.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_chat_message_service.r.g.dart';

@riverpod
Future<SendChatMessageService> sendChatMessageService(Ref ref) async {
  return SendChatMessageService(
    currentUserMasterPubkey: ref.watch(currentPubkeySelectorProvider),
    sendChatMessageService: ref.watch(sendE2eeChatMessageServiceProvider),
    getExistingConversationId: (String masterPubkey) {
      final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);
      if (currentUserMasterPubkey == null) {
        throw UserMasterPubkeyNotFoundException();
      }
      final participantsMasterPubkeys = [masterPubkey, currentUserMasterPubkey];

      return ref.read(existChatConversationIdProvider(participantsMasterPubkeys).future);
    },
  );
}

class SendChatMessageService {
  SendChatMessageService({
    required this.currentUserMasterPubkey,
    required this.sendChatMessageService,
    required this.getExistingConversationId,
  });

  final String? currentUserMasterPubkey;
  final SendE2eeChatMessageService sendChatMessageService;
  final Future<String?> Function(String pubkey) getExistingConversationId;

  Future<void> send({
    required String receiverPubkey,
    required String content,
    int? kind,
    List<MediaFile> mediaFiles = const [],
    List<List<String>>? tags,
  }) async {
    final currentPubkey = currentUserMasterPubkey;

    if (currentPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    final existingConversationId = await getExistingConversationId(receiverPubkey);

    final conversationId = existingConversationId ??
        generateConversationId(
          conversationType: ConversationType.direct,
          receiverMasterPubkeys: [receiverPubkey, currentPubkey],
        );

    await sendChatMessageService.sendMessage(
      tags: tags,
      kind: kind,
      content: content,
      mediaFiles: mediaFiles,
      conversationId: conversationId,
      participantsMasterPubkeys: [receiverPubkey, currentPubkey],
    );
  }
}

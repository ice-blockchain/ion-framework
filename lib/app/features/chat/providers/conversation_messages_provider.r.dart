// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_e2ee_message_status_provider.r.dart';
import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart';
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

    final stream = ref.watch(conversationMessageDaoProvider).getMessages(conversationId);

    final subscription = stream.listen((event) {
      final messages = event.entries.map((e) => e.value).expand((e) => e).toList()
        ..sortByCompare((e) => e.publishedAt, (a, b) => b.compareTo(a));
      _sendReadStatus(messages);
    });

    ref.onDispose(subscription.cancel);

    return stream;
  }

  Future<void> _sendReadStatus(List<EventMessage> messages) async {
    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

    if (currentUserMasterPubkey == null) {
      return;
    }

    final lastMessageFromOther =
        messages.where((e) => e.masterPubkey != currentUserMasterPubkey).firstOrNull;

    if (lastMessageFromOther == null) return;

    final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(lastMessageFromOther);
    final status = await ref.watch(conversationMessageDataDaoProvider).checkMessageStatus(
          eventReference: entity.toEventReference(),
          masterPubkey: currentUserMasterPubkey,
        );
    if (status == MessageDeliveryStatus.read) return;
    await (await ref.watch(sendE2eeMessageStatusServiceProvider.future)).sendMessageStatus(
      messageEventMessage: lastMessageFromOther,
      status: MessageDeliveryStatus.read,
    );
  }
}

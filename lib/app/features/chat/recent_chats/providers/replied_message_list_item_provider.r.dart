// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replied_message_list_item_provider.r.g.dart';

@Riverpod(keepAlive: true, dependencies: [])
Stream<EventMessage?> repliedMessageListItem(Ref ref, ChatMessageInfoItem messageItem) {
  final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(messageItem.eventMessage);

  final repliedEvent = entity.data.parentEvent;

  if (repliedEvent == null) {
    return Stream.value(null);
  }

  return ref.watch(conversationMessageDaoProvider).watchEventMessage(
        eventReference: repliedEvent.eventReference,
      );
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/extensions/event_message.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

extension ChatDatabaseEventMessageExtensions on EventMessage {
  EventMessageDbModel toChatDbModel(EventReference eventReference, {List<String>? wrapIds}) {
    return EventMessageDbModel(
      id: id,
      kind: kind,
      tags: tags,
      pubkey: pubkey,
      content: content,
      createdAt: createdAt,
      masterPubkey: masterPubkey,
      eventReference: eventReference,
      wrapIds: wrapIds,
    );
  }

  EventMessage toEventMessage() {
    return EventMessage(
      id: id,
      kind: kind,
      tags: tags,
      pubkey: pubkey,
      content: content,
      createdAt: createdAt,
      sig: null,
    );
  }
}

extension ChatDatabaseDbModelExtensions on EventMessageDbModel {
  EventMessage toEventMessage() {
    return EventMessage(
      id: id,
      kind: kind,
      tags: tags,
      pubkey: pubkey,
      content: content,
      createdAt: createdAt,
      sig: null,
    );
  }
}

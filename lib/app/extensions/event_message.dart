// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart'
    as event_messages_db;
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

extension KeysExtensions on EventMessage {
  String get masterPubkey {
    final masterPubkey =
        tags.firstWhereOrNull((tags) => tags[0] == MasterPubkeyTag.tagName)?.elementAtOrNull(1);

    if (masterPubkey == null) {
      throw EventMasterPubkeyNotFoundException(eventId: id);
    }

    return masterPubkey;
  }

  event_messages_db.EventMessageDbModel toIonConnectDbModel(EventReference eventReference) {
    return event_messages_db.EventMessageDbModel(
      id: id,
      kind: kind,
      pubkey: pubkey,
      masterPubkey: masterPubkey,
      createdAt: createdAt,
      sig: sig,
      content: content,
      tags: tags,
      eventReference: eventReference,
    );
  }

  event_messages_db.ChatEventMessageDbModel toChatDbModel(EventReference eventReference) {
    return event_messages_db.ChatEventMessageDbModel(
      id: id,
      kind: kind,
      pubkey: pubkey,
      masterPubkey: masterPubkey,
      createdAt: createdAt,
      content: content,
      tags: tags,
      eventReference: eventReference,
    );
  }
}

extension IonConnectEventMessageDbModelExtensions on event_messages_db.ChatEventMessageDbModel {
  EventMessage toEventMessage() {
    return EventMessage(
      id: id,
      kind: kind,
      pubkey: pubkey,
      createdAt: createdAt,
      sig: null,
      content: content,
      tags: tags,
    );
  }
}

extension ChatEventMessageDbModelExtensions on event_messages_db.EventMessageDbModel {
  EventMessage toEventMessage() {
    return EventMessage(
      id: id,
      kind: kind,
      pubkey: pubkey,
      createdAt: createdAt,
      content: content,
      tags: tags,
      sig: null,
    );
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion_connect_cache/src/database/event_messages_database.d.dart';
import 'package:nostr_dart/nostr_dart.dart';

extension IonConnectCacheEventMessageDbModelExtensions on EventMessageCacheDbModel {
  EventMessage toEventMessage() {
    return EventMessage(
      id: id,
      kind: kind,
      pubkey: pubkey,
      createdAt: createdAt,
      sig: sig,
      content: content,
      //tags: tags,
      tags: [],
    );
  }

  static EventMessageCacheDbModel fromEventMessage(EventMessage eventMessage) {
    return EventMessageCacheDbModel(
      id: eventMessage.id,
      kind: eventMessage.kind,
      pubkey: eventMessage.pubkey,
      createdAt: eventMessage.createdAt,
      sig: eventMessage.sig,
      content: eventMessage.content,
      //tags: eventMessage.tags,
      //masterPubkey: _extractMasterPubkey(eventMessage),
      masterPubkey: '',
    );
  }
}

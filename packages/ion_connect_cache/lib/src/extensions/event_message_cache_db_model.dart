// SPDX-License-Identifier: ice License 1.0

import 'package:ion_connect_cache/src/database/ion_connect_cache_database.d.dart';
import 'package:nostr_dart/nostr_dart.dart';

extension IonConnectCacheEventMessageDbModelExtensions on EventMessageCacheDbModel {
  EventMessage toEventMessage() {
    return EventMessage(
      id: id,
      kind: kind,
      tags: tags,
      pubkey: pubkey,
      content: content,
      createdAt: createdAt,
      sig: sig,
    );
  }

  static EventMessageCacheDbModel fromEventMessage({
    required String cacheKey,
    required String masterPubkey,
    required EventMessage eventMessage,
  }) {
    return EventMessageCacheDbModel(
      cacheKey: cacheKey,
      id: eventMessage.id,
      kind: eventMessage.kind,
      tags: eventMessage.tags,
      masterPubkey: masterPubkey,
      pubkey: eventMessage.pubkey,
      content: eventMessage.content,
      createdAt: eventMessage.createdAt,
      insertedAt: DateTime.now().millisecondsSinceEpoch,
      sig: eventMessage.sig,
    );
  }
}

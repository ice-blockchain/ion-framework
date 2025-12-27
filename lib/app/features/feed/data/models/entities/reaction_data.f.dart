// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';

part 'reaction_data.f.freezed.dart';

@Freezed(equal: false)
class ReactionEntity with _$ReactionEntity, IonConnectEntity, ImmutableEntity, CacheableEntity {
  const factory ReactionEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required ReactionData data,
    EventMessage? eventMessage,
  }) = _ReactionEntity;

  const ReactionEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/25.md
  factory ReactionEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return ReactionEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: ReactionData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  @override
  String get cacheKey =>
      cacheKeyBuilder(eventReference: data.eventReference, content: data.content);

  static String cacheKeyBuilder({
    required EventReference eventReference,
    required String content,
  }) =>
      '$eventReference:$content';

  static const int kind = 7;

  static const String likeSymbol = '+';
}

@freezed
class ReactionData with _$ReactionData implements EventSerializable {
  const factory ReactionData({
    required int kind,
    required String content,
    required EventReference eventReference,
  }) = _ReactionData;

  const ReactionData._();

  factory ReactionData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final eventId = tags['e']?.first[1];
    final eventRef = tags['a']?.first[1];
    final pubkey = tags['p']?.first[1];
    final kind = int.tryParse(tags['k']!.first[1]);

    if (pubkey == null || kind == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    final eventReference = eventRef != null
        ? ReplaceableEventReference.fromString(eventRef)
        : eventId != null
            ? ImmutableEventReference(eventId: eventId, masterPubkey: pubkey)
            : null;

    if (eventReference == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    return ReactionData(
      kind: kind,
      eventReference: eventReference,
      content: eventMessage.content,
    );
  }

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) {
    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt,
      kind: ReactionEntity.kind,
      content: content,
      tags: [
        ...tags,
        ['p', eventReference.masterPubkey],
        ['k', kind.toString()],
        eventReference.toTag(),
      ],
    );
  }
}

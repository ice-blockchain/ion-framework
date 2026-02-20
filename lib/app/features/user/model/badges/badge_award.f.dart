// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';

part 'badge_award.f.freezed.dart';

@Freezed(equal: false)
class BadgeAwardEntity
    with IonConnectEntity, ImmutableEntity, CacheableEntity, _$BadgeAwardEntity
    implements EntityEventSerializable, DbCacheableEntity {
  const factory BadgeAwardEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required BadgeAwardData data,
    EventMessage? eventMessage,
  }) = _BadgeAwardEntity;

  const BadgeAwardEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/58.md
  factory BadgeAwardEntity.fromEventMessage(EventMessage ev) {
    if (ev.kind != kind) {
      throw IncorrectEventKindException(ev.id, kind: kind);
    }
    return BadgeAwardEntity(
      id: ev.id,
      pubkey: ev.pubkey,
      masterPubkey: ev.pubkey,
      signature: ev.sig!,
      createdAt: ev.createdAt,
      data: BadgeAwardData.fromEventMessage(ev),
      eventMessage: ev,
    );
  }

  @override
  FutureOr<EventMessage> toEntityEventMessage() => eventMessage ?? toEventMessage(data);

  static const int kind = 8;
}

@freezed
class BadgeAwardData with _$BadgeAwardData implements EventSerializable {
  const factory BadgeAwardData({
    /// The definition reference (`a` tag)
    required ReplaceableEventReference badgeDefinitionRef,

    /// One or more recipients pub keys (`p` tags)
    required List<String> recipientsPubKeys,
  }) = _BadgeAwardData;

  const BadgeAwardData._();

  factory BadgeAwardData.fromEventMessage(EventMessage eventMessage) {
    final badgeDefinitionRef = eventMessage.tags.firstWhereOrNull((t) => t[0] == 'a')?[1];
    if (badgeDefinitionRef == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    final recipientsPubKeys = eventMessage.tags
        .where((t) => t[0] == 'p')
        .map((t) => t.elementAtOrNull(1))
        .nonNulls
        .toList();

    return BadgeAwardData(
      badgeDefinitionRef: ReplaceableEventReference.fromString(badgeDefinitionRef),
      recipientsPubKeys: recipientsPubKeys,
    );
  }

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    int? createdAt,
    String content = '',
    List<List<String>> tags = const [],
  }) {
    final built = <List<String>>[
      badgeDefinitionRef.toTag(),
      for (final recipientPubKey in recipientsPubKeys) ['p', recipientPubKey],
    ];
    return EventMessage.fromData(
      signer: signer,
      content: content,
      createdAt: createdAt,
      kind: BadgeAwardEntity.kind,
      tags: [...tags, ...built],
    );
  }
}

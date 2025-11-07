// SPDX-License-Identifier: ice License 1.0

// profile_badges.f.dart

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/event_message.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';

part 'profile_badges.f.freezed.dart';

@Freezed(equal: false)
class ProfileBadgesEntity
    with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$ProfileBadgesEntity
    implements EntityEventSerializable, DbCacheableEntity {
  const factory ProfileBadgesEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required ProfileBadgesData data,
    EventMessage? eventMessage,
  }) = _ProfileBadgesEntity;

  const ProfileBadgesEntity._();

  /// NIP-58 Profile Badges (replaceable d="profile_badges")  [oai_citation:8‡GitHub](https://github.com/nostr-protocol/nips/raw/master/58.md)
  factory ProfileBadgesEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }
    return ProfileBadgesEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: ProfileBadgesData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  @override
  FutureOr<EventMessage> toEntityEventMessage() => eventMessage ?? toEventMessage(data);

  static const int kind = 30008;
  static const String dTag = 'profile_badges';
}

@freezed
class ProfileBadgesData
    with _$ProfileBadgesData
    implements EventSerializable, ReplaceableEntityData {
  const factory ProfileBadgesData({
    /// Ordered list of badge entries (a+e pairs)  [oai_citation:9‡GitHub](https://github.com/nostr-protocol/nips/raw/master/58.md)
    required List<BadgeEntry> entries,
  }) = _ProfileBadgesData;

  const ProfileBadgesData._();

  factory ProfileBadgesData.fromEventMessage(EventMessage ev) {
    final tags = ev.tags;
    final d = tags.firstWhereOrNull((t) => t[0] == 'd' && t[1] == ProfileBadgesEntity.dTag);
    if (d == null) {
      throw IncorrectEventTagsException(eventId: ev.id);
    }

    final entries = <BadgeEntry>[];
    for (var i = tags.indexOf(d) + 1; i + 1 < tags.length; i += 2) {
      final a = tags[i];
      final e = tags[i + 1];
      if (a[0] != 'a' || e[0] != 'e' || a.length < 2 || e.length < 2) continue;
      entries.add(
        BadgeEntry(
          definitionRef: ReplaceableEventReference.fromString(a[1]),
          awardId: e[1],
        ),
      );
    }

    return ProfileBadgesData(entries: entries);
  }

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    int? createdAt,
    String content = '',
    List<List<String>> tags = const [],
  }) {
    final built = <List<String>>[
      ['d', ProfileBadgesEntity.dTag],
      for (final entry in entries) ...[
        entry.definitionRef.toTag(),
        ['e', entry.awardId],
      ],
    ];
    return EventMessage.fromData(
      signer: signer,
      content: content,
      createdAt: createdAt,
      kind: ProfileBadgesEntity.kind,
      tags: [...tags, ...built],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      masterPubkey: pubkey,
      dTag: ProfileBadgesEntity.dTag,
      kind: ProfileBadgesEntity.kind,
    );
  }
}

@immutable
class BadgeEntry {
  const BadgeEntry({
    required this.definitionRef,
    required this.awardId,
  });

  final ReplaceableEventReference definitionRef;
  final String awardId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BadgeEntry && other.definitionRef == definitionRef && other.awardId == awardId;
  }

  @override
  int get hashCode => Object.hash(definitionRef, awardId);
}

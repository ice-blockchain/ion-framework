// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';

part 'badge_definition.f.freezed.dart';

class Thumbnail {
  Thumbnail({required this.url, this.dimensions});

  final String url;
  final String? dimensions;
}

@Freezed(equal: false)
class BadgeDefinitionEntity
    with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$BadgeDefinitionEntity
    implements EntityEventSerializable, DbCacheableEntity {
  const factory BadgeDefinitionEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required BadgeDefinitionData data,
    EventMessage? eventMessage,
  }) = _BadgeDefinitionEntity;

  const BadgeDefinitionEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/58.md
  factory BadgeDefinitionEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }
    return BadgeDefinitionEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.pubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: BadgeDefinitionData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  @override
  FutureOr<EventMessage> toEntityEventMessage() => eventMessage ?? toEventMessage(data);

  static const int kind = 30009;
  static const String verifiedBadgeDTag = 'verified';

  // Actual d tag is username_proof_of_ownership~<username>
  static const String usernameProofOfOwnershipBadgeDTag = 'username_proof_of_ownership~';
}

@freezed
class BadgeDefinitionData
    with _$BadgeDefinitionData
    implements EventSerializable, ReplaceableEntityData {
  const factory BadgeDefinitionData({
    /// The unique badge identifier (the `d` tag)
    required ReplaceableEventIdentifier badge,

    /// Optional human-readable name (`name` tag)
    String? name,

    /// Optional description (`description` tag)
    String? description,

    /// Optional high-res image URL (`image` tag)
    String? imageUrl,

    /// Optional dimensions string for image (“WxH”)
    String? imageDimensions,

    /// Zero or more thumbnail URLs + dims (`thumb` tags)
    @Default(<Thumbnail>[]) List<Thumbnail> thumbs,
  }) = _BadgeDefinitionData;

  const BadgeDefinitionData._();

  factory BadgeDefinitionData.fromEventMessage(EventMessage eventMessage) {
    final tags = eventMessage.tags;

    final badge = eventMessage.tags
        .firstWhereOrNull((tag) => tag[0] == ReplaceableEventIdentifier.tagName)?[1];
    if (badge == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    // optional tags
    final name = tags.firstWhereOrNull((t) => t[0] == 'name')?.elementAtOrNull(1);
    final description = tags.firstWhereOrNull((t) => t[0] == 'description')?.elementAtOrNull(1);

    final imageTag = tags.firstWhereOrNull((t) => t[0] == 'image');
    String? imageUrl;
    String? imageDimensions;
    if (imageTag != null) {
      imageUrl = imageTag.elementAtOrNull(1);
      imageDimensions = imageTag.elementAtOrNull(2);
    }

    // thumbs
    final thumbs = tags
        .where((t) => t[0] == 'thumb')
        .map(
          (t) => Thumbnail(
            url: t.elementAtOrNull(1) ?? '',
            dimensions: t.elementAtOrNull(2),
          ),
        )
        .toList();

    return BadgeDefinitionData(
      badge: ReplaceableEventIdentifier(value: badge),
      name: name,
      description: description,
      imageUrl: imageUrl,
      imageDimensions: imageDimensions,
      thumbs: thumbs,
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
      badge.toTag(),
      if (name != null) ['name', name!],
      if (description != null) ['description', description!],
      if (imageUrl != null) ['image', imageUrl!, if (imageDimensions != null) imageDimensions!],
      for (final t in thumbs) ['thumb', t.url, if (t.dimensions != null) t.dimensions!],
    ];

    return EventMessage.fromData(
      signer: signer,
      content: content,
      createdAt: createdAt,
      kind: BadgeDefinitionEntity.kind,
      tags: [...tags, ...built],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      masterPubkey: pubkey,
      dTag: badge.value,
      kind: BadgeDefinitionEntity.kind,
    );
  }
}

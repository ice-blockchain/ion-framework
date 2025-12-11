// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_kind.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';

part 'community_token_definition.f.freezed.dart';

enum CommunityTokenDefinitionType {
  /// Original token definition event.
  ///   Should be created when the related event is created.
  ///   Root for all other token related events.
  original,

  /// Action token definition event - "first buy" action.
  ///   Should be created when a user buys token for the first time.
  firstBuyAction,
}

@Freezed(equal: false)
class CommunityTokenDefinitionEntity
    with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$CommunityTokenDefinitionEntity
    implements EntityEventSerializable {
  const factory CommunityTokenDefinitionEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required CommunityTokenDefinition data,
    EventMessage? eventMessage,
  }) = _CommunityTokenDefinitionEntity;

  const CommunityTokenDefinitionEntity._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/ICIP-11000.md#community-token-definition-event
  factory CommunityTokenDefinitionEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw Exception('Incorrect event kind ${eventMessage.kind}, expected $kind');
    }

    return CommunityTokenDefinitionEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: CommunityTokenDefinition.fromEventMessage(eventMessage),
    );
  }

  static const kind = 31175;

  @override
  FutureOr<EventMessage> toEntityEventMessage() => eventMessage ?? toEventMessage(data);
}

@freezed
class CommunityTokenDefinition
    with _$CommunityTokenDefinition
    implements ReplaceableEntityData, EventSerializable {
  const factory CommunityTokenDefinition({
    required EventReference eventReference,
    required int kind,
    required String dTag,
    required CommunityTokenDefinitionType type,
    required List<RelatedHashtag> relatedHashtags,
  }) = _CommunityTokenDefinition;

  const CommunityTokenDefinition._();

  factory CommunityTokenDefinition.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final eventReference =
        (tags[ReplaceableEventReference.tagName] ?? tags[ImmutableEventReference.tagName])
            ?.map(EventReference.fromTag)
            .firstOrNull;
    final kind = tags[EventKind.tagName]?.map(EventKind.fromTag).firstOrNull?.value;
    final dTag = tags[ReplaceableEventIdentifier.tagName]
        ?.map(ReplaceableEventIdentifier.fromTag)
        .firstOrNull
        ?.value;

    if (eventReference == null || kind == null || dTag == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    final type = tags[RelatedHashtag.tagName]?.firstWhereOrNull(
              (tag) => RelatedHashtag.fromTag(tag).value == communityTokenActionTopic,
            ) ==
            null
        ? CommunityTokenDefinitionType.original
        : CommunityTokenDefinitionType.firstBuyAction;

    return CommunityTokenDefinition(
      eventReference: eventReference,
      kind: kind,
      dTag: dTag,
      type: type,
      relatedHashtags: _buildRelatedHashtags(type),
    );
  }

  factory CommunityTokenDefinition.fromEventReference({
    required EventReference eventReference,
    required int kind,
    required CommunityTokenDefinitionType type,
  }) {
    final dTag = switch (eventReference) {
      ImmutableEventReference() => eventReference.eventId,
      ReplaceableEventReference() when eventReference.kind == UserMetadataEntity.kind =>
        eventReference.masterPubkey,
      ReplaceableEventReference() => '${eventReference.kind}.${eventReference.dTag}',
      _ => throw UnsupportedEventReference(eventReference),
    };
    return CommunityTokenDefinition(
      eventReference: eventReference,
      kind: kind,
      dTag: dTag,
      type: type,
      relatedHashtags: _buildRelatedHashtags(type),
    );
  }

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) async {
    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt,
      kind: CommunityTokenDefinitionEntity.kind,
      content: '',
      tags: [
        ...tags,
        eventReference.toTag(),
        ...relatedHashtags.map((hashtag) => hashtag.toTag()),
        ReplaceableEventIdentifier(value: dTag).toTag(),
        EventKind(value: kind).toTag(),
        if (type == CommunityTokenDefinitionType.firstBuyAction)
          RelatedPubkey(value: eventReference.masterPubkey).toTag(),
      ],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: CommunityTokenDefinitionEntity.kind,
      masterPubkey: pubkey,
      dTag: dTag,
    );
  }

  static List<RelatedHashtag> _buildRelatedHashtags(CommunityTokenDefinitionType type) {
    return [
      const RelatedHashtag(value: communityTokenTopic),
      if (type == CommunityTokenDefinitionType.firstBuyAction)
        const RelatedHashtag(value: communityTokenActionTopic),
    ];
  }
}

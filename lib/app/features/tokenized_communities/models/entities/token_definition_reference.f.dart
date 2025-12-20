// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';

part 'token_definition_reference.f.freezed.dart';

/// Internal app entity representing token definition reference for a given
/// token external address.
///
/// Might be user for easy lookups of token definitions (original or first-buy) by external address.
@Freezed(equal: false)
class TokenDefinitionReferenceEntity
    with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$TokenDefinitionReferenceEntity
    implements EntityEventSerializable, DbCacheableEntity {
  const factory TokenDefinitionReferenceEntity({
    required String masterPubkey,
    required TokenDefinitionReference data,
    @Default('') String id,
    @Default('') String pubkey,
    @Default('') String signature,
    @Default(0) int createdAt,
  }) = _TokenDefinitionReferenceEntity;

  const TokenDefinitionReferenceEntity._();

  factory TokenDefinitionReferenceEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return TokenDefinitionReferenceEntity(
      masterPubkey: '',
      data: TokenDefinitionReference.fromEventMessage(eventMessage),
    );
  }

  factory TokenDefinitionReferenceEntity.fromData({
    required ReplaceableEventReference tokenDefinitionReference,
    required String externalAddress,
    required CommunityTokenDefinitionIonType type,
  }) {
    return TokenDefinitionReferenceEntity(
      masterPubkey: '',
      data: TokenDefinitionReference(
        externalAddress: externalAddress,
        tokenDefinitionReference: tokenDefinitionReference,
        relatedHashtags: type == CommunityTokenDefinitionIonType.firstBuyAction
            ? [const RelatedHashtag(value: communityTokenActionTopic)]
            : [],
      ),
    );
  }

  factory TokenDefinitionReferenceEntity.forDefinition({
    required CommunityTokenDefinitionEntity tokenDefinition,
  }) {
    return TokenDefinitionReferenceEntity(
      masterPubkey: '',
      data: TokenDefinitionReference.forDefinition(
        tokenDefinition: tokenDefinition,
      ),
    );
  }

  @override
  FutureOr<EventMessage> toEntityEventMessage() => toEventMessage(data);

  static const int kind = -31175;
}

@freezed
class TokenDefinitionReference
    with _$TokenDefinitionReference
    implements EventSerializable, ReplaceableEntityData {
  const factory TokenDefinitionReference({
    required String externalAddress,
    required ReplaceableEventReference tokenDefinitionReference,
    required List<RelatedHashtag> relatedHashtags,
  }) = _TokenDefinitionReference;

  factory TokenDefinitionReference.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    return TokenDefinitionReference(
      externalAddress: tags['h']!.first.last,
      relatedHashtags: tags[RelatedHashtag.tagName]?.map(RelatedHashtag.fromTag).toList() ?? [],
      tokenDefinitionReference:
          ReplaceableEventReference.fromTag(tags[ReplaceableEventReference.tagName]!.first),
    );
  }

  factory TokenDefinitionReference.forDefinition({
    required CommunityTokenDefinitionEntity tokenDefinition,
  }) {
    final type = tokenDefinition.data is CommunityTokenDefinitionIon
        ? (tokenDefinition.data as CommunityTokenDefinitionIon).type
        : CommunityTokenDefinitionIonType.original;
    return TokenDefinitionReference(
      externalAddress: tokenDefinition.data.externalAddress,
      relatedHashtags: type == CommunityTokenDefinitionIonType.firstBuyAction
          ? [const RelatedHashtag(value: communityTokenActionTopic)]
          : [],
      tokenDefinitionReference: tokenDefinition.toEventReference(),
    );
  }

  const TokenDefinitionReference._();

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) {
    return EventMessage.fromData(
      content: '',
      signer: signer,
      createdAt: createdAt,
      kind: TokenDefinitionReferenceEntity.kind,
      tags: [
        ['h', externalAddress],
        ...relatedHashtags.map((hashtag) => hashtag.toTag()),
        tokenDefinitionReference.toTag(),
        ...tags,
      ],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return buildEventReference(
      externalAddress: externalAddress,
      type: relatedHashtags.any(
        (hashtag) => hashtag.value == communityTokenActionTopic,
      )
          ? CommunityTokenDefinitionIonType.firstBuyAction
          : CommunityTokenDefinitionIonType.original,
    );
  }

  static ReplaceableEventReference buildEventReference({
    required String externalAddress,
    required CommunityTokenDefinitionIonType type,
  }) {
    return ReplaceableEventReference(
      kind: TokenDefinitionReferenceEntity.kind,
      masterPubkey: '',
      dTag: '${type.name}${externalAddress.replaceAll(EventReference.separator, '.')}',
    );
  }
}

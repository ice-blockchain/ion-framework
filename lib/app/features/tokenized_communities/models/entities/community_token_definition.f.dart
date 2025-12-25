// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/extensions/object.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_kind.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';

part 'community_token_definition.f.freezed.dart';

enum CommunityTokenPlatform {
  ion('ion'),
  x('x.com');

  const CommunityTokenPlatform(this.value);

  final String value;
}

enum CommunityTokenDefinitionIonType {
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
    implements EntityEventSerializable, DbCacheableEntity {
  const factory CommunityTokenDefinitionEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required CommunityTokenDefinition data,
  }) = _CommunityTokenDefinitionEntity;

  const CommunityTokenDefinitionEntity._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/ICIP-11000.md#community-token-definition-event
  factory CommunityTokenDefinitionEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw Exception('Incorrect event kind ${eventMessage.kind}, expected $kind');
    }

    final data = CommunityTokenDefinition.fromEventMessage(eventMessage);

    return CommunityTokenDefinitionEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: data.platform == CommunityTokenPlatform.ion
          ? eventMessage.masterPubkey
          : eventMessage.pubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: data,
    );
  }

  static const kind = 31175;

  @override
  FutureOr<EventMessage> toEntityEventMessage() => toEventMessage(data);
}

abstract class CommunityTokenDefinition implements ReplaceableEntityData, EventSerializable {
  const CommunityTokenDefinition();

  factory CommunityTokenDefinition.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    final kind = tags[EventKind.tagName]?.map(EventKind.fromTag).firstOrNull?.value;
    final dTag = tags[ReplaceableEventIdentifier.tagName]
        ?.map(ReplaceableEventIdentifier.fromTag)
        .firstOrNull
        ?.value;
    final platform = tags['platform']?.firstOrNull?.elementAtOrNull(1)?.let(
              (value) => CommunityTokenPlatform.values.firstWhereOrNull((e) => e.value == value),
            ) ??
        CommunityTokenPlatform.ion;
    final relatedHashtags =
        tags[RelatedHashtag.tagName]?.map(RelatedHashtag.fromTag).toList() ?? [];

    if (kind == null || dTag == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    if (platform == CommunityTokenPlatform.ion) {
      final eventReference =
          (tags[ReplaceableEventReference.tagName] ?? tags[ImmutableEventReference.tagName])
              ?.map(EventReference.fromTag)
              .firstOrNull;

      final type = tags[RelatedHashtag.tagName]?.firstWhereOrNull(
                (tag) => RelatedHashtag.fromTag(tag).value == communityTokenActionTopic,
              ) ==
              null
          ? CommunityTokenDefinitionIonType.original
          : CommunityTokenDefinitionIonType.firstBuyAction;

      if (eventReference == null) {
        throw IncorrectEventTagsException(eventId: eventMessage.id);
      }

      return CommunityTokenDefinitionIon(
        eventReference: eventReference,
        kind: kind,
        dTag: dTag,
        type: type,
        platform: CommunityTokenPlatform.ion,
        relatedHashtags: relatedHashtags,
      );
    } else {
      final externalId = tags['h']?.firstOrNull?.elementAtOrNull(1);

      if (externalId == null) {
        throw IncorrectEventTagsException(eventId: eventMessage.id);
      }

      return CommunityTokenDefinitionExternal(
        externalId: externalId,
        kind: kind,
        dTag: dTag,
        platform: platform,
        relatedHashtags: relatedHashtags,
      );
    }
  }

  int get kind;
  String get dTag;
  CommunityTokenPlatform get platform;
  List<RelatedHashtag> get relatedHashtags;

  String get externalAddress => switch (this) {
        CommunityTokenDefinitionIon(:final eventReference) => eventReference.toString(),
        CommunityTokenDefinitionExternal(:final externalId) => externalId,
        _ => throw UnsupportedError('Unsupported CommunityTokenDefinition type'),
      };
}

/// Ion-based Community Token Definition
/// It might be a token for a user or a post or any other Ion Connect event.
/// It always has [eventReference] pointing to the original Ion Connect event.
/// It also has [type] defining whether this is a "first-buy" or "original" definition.
@freezed
class CommunityTokenDefinitionIon
    with _$CommunityTokenDefinitionIon
    implements CommunityTokenDefinition {
  const factory CommunityTokenDefinitionIon({
    required EventReference eventReference,
    required int kind,
    required String dTag,
    required CommunityTokenDefinitionIonType type,
    required CommunityTokenPlatform platform,
    required List<RelatedHashtag> relatedHashtags,
  }) = _CommunityTokenDefinitionIon;

  factory CommunityTokenDefinitionIon.fromEventReference({
    required EventReference eventReference,
    required int kind,
    required CommunityTokenDefinitionIonType type,
  }) {
    final dTag = switch (eventReference) {
      ImmutableEventReference() => eventReference.eventId,
      ReplaceableEventReference() when eventReference.kind == UserMetadataEntity.kind =>
        eventReference.masterPubkey,
      ReplaceableEventReference() => '${eventReference.kind}.${eventReference.dTag}',
      _ => throw UnsupportedEventReference(eventReference),
    };
    return CommunityTokenDefinitionIon(
      eventReference: eventReference,
      kind: kind,
      dTag: dTag,
      type: type,
      platform: CommunityTokenPlatform.ion,
      relatedHashtags: _buildRelatedHashtags(type),
    );
  }

  const CommunityTokenDefinitionIon._();

  @override
  String get externalAddress => eventReference.toString();

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
        ['platform', CommunityTokenPlatform.ion.value],
        ...relatedHashtags.map((hashtag) => hashtag.toTag()),
        ReplaceableEventIdentifier(value: dTag).toTag(),
        EventKind(value: kind).toTag(),
        if (type == CommunityTokenDefinitionIonType.firstBuyAction)
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

  static List<RelatedHashtag> _buildRelatedHashtags(CommunityTokenDefinitionIonType type) {
    return [
      const RelatedHashtag(value: communityTokenTopic),
      if (type == CommunityTokenDefinitionIonType.firstBuyAction)
        const RelatedHashtag(value: communityTokenActionTopic),
    ];
  }
}

/// External Community Token Definition
/// It might be a token for some external platform, for example for x platform.
/// It always has [externalId] that holds the external platform token identifier.
/// It is always "original" type definition (we don't have "first-buy" for external tokens).
@freezed
class CommunityTokenDefinitionExternal
    with _$CommunityTokenDefinitionExternal
    implements CommunityTokenDefinition {
  const factory CommunityTokenDefinitionExternal({
    required String externalId,
    required int kind,
    required String dTag,
    required CommunityTokenPlatform platform,
    required List<RelatedHashtag> relatedHashtags,
  }) = _CommunityTokenDefinitionExternal;

  const CommunityTokenDefinitionExternal._();

  @override
  String get externalAddress => externalId;

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
        ['h', externalId],
        ['platform', platform.value],
        ...relatedHashtags.map((hashtag) => hashtag.toTag()),
        ReplaceableEventIdentifier(value: dTag).toTag(),
        const RelatedHashtag(value: communityTokenTopic).toTag(),
        EventKind(value: kind).toTag(),
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
}

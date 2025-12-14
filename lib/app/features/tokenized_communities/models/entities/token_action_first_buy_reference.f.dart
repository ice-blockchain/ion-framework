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
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';

part 'token_action_first_buy_reference.f.freezed.dart';

/// Internal app entity representing the first buy action reference for a given
/// community token action and master pubkey.
///
@Freezed(equal: false)
class TokenActionFirstBuyReferenceEntity
    with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$TokenActionFirstBuyReferenceEntity
    implements EntityEventSerializable {
  const factory TokenActionFirstBuyReferenceEntity({
    required String masterPubkey,
    required TokenActionFirstBuyReference data,
    @Default('') String id,
    @Default('') String pubkey,
    @Default('') String signature,
    @Default(0) int createdAt,
  }) = _TokenActionFirstBuyReferenceEntity;

  const TokenActionFirstBuyReferenceEntity._();

  factory TokenActionFirstBuyReferenceEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return TokenActionFirstBuyReferenceEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: TokenActionFirstBuyReference.fromEventMessage(eventMessage),
    );
  }

  factory TokenActionFirstBuyReferenceEntity.fromCommunityTokenAction(
    CommunityTokenActionEntity entity,
  ) {
    return TokenActionFirstBuyReferenceEntity(
      masterPubkey: entity.masterPubkey,
      data: TokenActionFirstBuyReference.fromCommunityTokenAction(entity),
    );
  }

  @override
  FutureOr<EventMessage> toEntityEventMessage() => toEventMessage(data);

  static const int kind = -1175;
}

@freezed
class TokenActionFirstBuyReference
    with _$TokenActionFirstBuyReference
    implements EventSerializable, ReplaceableEntityData {
  const factory TokenActionFirstBuyReference({
    required EventReference tokenActionReference,
    required EventReference tokenDefinitionReference,
  }) = _TokenActionFirstBuyReference;

  factory TokenActionFirstBuyReference.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    return TokenActionFirstBuyReference(
      tokenActionReference:
          ImmutableEventReference.fromTag(tags[ImmutableEventReference.tagName]!.first),
      tokenDefinitionReference:
          ReplaceableEventReference.fromTag(tags[ReplaceableEventReference.tagName]!.first),
    );
  }

  factory TokenActionFirstBuyReference.fromCommunityTokenAction(
    CommunityTokenActionEntity action,
  ) {
    return TokenActionFirstBuyReference(
      tokenActionReference: action.toEventReference(),
      tokenDefinitionReference: action.data.definitionReference,
    );
  }

  const TokenActionFirstBuyReference._();

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
      kind: TokenActionFirstBuyReferenceEntity.kind,
      tags: [
        tokenActionReference.toTag(),
        tokenDefinitionReference.toTag(),
        ...tags,
      ],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return buildEventReference(
      masterPubkey: pubkey,
      tokenDefinitionReference: tokenDefinitionReference,
    );
  }

  static ReplaceableEventReference buildEventReference({
    required String masterPubkey,
    required EventReference tokenDefinitionReference,
  }) {
    return ReplaceableEventReference(
      kind: TokenActionFirstBuyReferenceEntity.kind,
      masterPubkey: masterPubkey,
      dTag: tokenDefinitionReference is ReplaceableEventReference
          ? tokenDefinitionReference.dTag
          : tokenDefinitionReference.toString(),
    );
  }
}

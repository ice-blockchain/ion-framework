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
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';

part 'community_token_definition_reference.f.freezed.dart';

/// Internal app entity representing token definition reference for a given
/// token external address.
///
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
      masterPubkey: eventMessage.masterPubkey,
      data: TokenDefinitionReference.fromEventMessage(eventMessage),
    );
  }

  factory TokenDefinitionReferenceEntity.fromData({
    required ReplaceableEventReference tokenDefinitionReference,
    required String externalAddress,
  }) {
    return TokenDefinitionReferenceEntity(
      masterPubkey: tokenDefinitionReference.masterPubkey,
      data: TokenDefinitionReference(
        externalAddress: externalAddress,
        tokenDefinitionReference: tokenDefinitionReference,
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
  }) = _TokenDefinitionReference;

  factory TokenDefinitionReference.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    return TokenDefinitionReference(
      externalAddress: tags['h']!.first.last,
      tokenDefinitionReference:
          ReplaceableEventReference.fromTag(tags[ReplaceableEventReference.tagName]!.first),
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
        tokenDefinitionReference.toTag(),
        ...tags,
      ],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return buildEventReference(externalAddress: externalAddress);
  }

  static ReplaceableEventReference buildEventReference({
    required String externalAddress,
  }) {
    return ReplaceableEventReference(
      kind: TokenDefinitionReferenceEntity.kind,
      masterPubkey: '',
      dTag: externalAddress.replaceAll(EventReference.separator, '.'),
    );
  }
}

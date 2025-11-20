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
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';

part 'interest_set.f.freezed.dart';

enum InterestSetType { languages, unknown }

@Freezed(equal: false)
class InterestSetEntity
    with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$InterestSetEntity {
  const factory InterestSetEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required InterestSetData data,
    EventMessage? eventMessage,
  }) = _InterestSetEntity;

  const InterestSetEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/51.md#sets
  factory InterestSetEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return InterestSetEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: InterestSetData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  static const int kind = 30015;
}

@freezed
class InterestSetData with _$InterestSetData implements EventSerializable, ReplaceableEntityData {
  const factory InterestSetData({
    required InterestSetType type,
    required List<String> hashtags,
  }) = _InterestSetData;

  const InterestSetData._();

  factory InterestSetData.fromEventMessage(EventMessage eventMessage) {
    final typeName = eventMessage.tags
        .firstWhereOrNull((tag) => tag[0] == ReplaceableEventIdentifier.tagName)?[1];

    if (typeName == null) {
      throw Exception('InterestSet event should have `${ReplaceableEventIdentifier.tagName}` tag');
    }

    return InterestSetData(
      type: InterestSetType.values.asNameMap()[typeName] ?? InterestSetType.unknown,
      hashtags: eventMessage.tags.where((tag) => tag[0] == 't').map((tag) => tag[1]).toList(),
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
      kind: InterestSetEntity.kind,
      tags: [
        ...tags,
        ReplaceableEventIdentifier(value: type.toShortString()).toTag(),
        ...hashtags.map((hashtag) => ['t', hashtag]),
      ],
      content: '',
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: InterestSetEntity.kind,
      masterPubkey: pubkey,
      dTag: type.toShortString(),
    );
  }
}

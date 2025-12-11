// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';

part 'generic_repost.f.freezed.dart';

@Freezed(equal: false)
class GenericRepostEntity
    with _$GenericRepostEntity, IonConnectEntity, ImmutableEntity, CacheableEntity {
  const factory GenericRepostEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required GenericRepostData data,
  }) = _GenericRepostEntity;

  const GenericRepostEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/18.md#generic-reposts
  factory GenericRepostEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return GenericRepostEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      signature: eventMessage.sig ?? '',
      createdAt: eventMessage.createdAt,
      masterPubkey: eventMessage.masterPubkey,
      data: GenericRepostData.fromEventMessage(eventMessage),
    );
  }

  static const int kind = 16;

  static const int modifiablePostRepostKind = 1630175;

  static const int articleRepostKind = 1630023;

  static const int communityTokenDefinitionRepostKind = 1631175;

  static const int communityTokenActionRepostKind = 161175;
}

@freezed
class GenericRepostData with _$GenericRepostData implements EventSerializable {
  const factory GenericRepostData({
    required int kind,
    required EventReference eventReference,
    EventMessage? repostedEvent,
  }) = _GenericRepostData;

  const GenericRepostData._();

  factory GenericRepostData.fromEventMessage(EventMessage eventMessage) {
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

    return GenericRepostData(
      kind: kind,
      eventReference: eventReference,
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
      kind: GenericRepostEntity.kind,
      content: repostedEvent != null ? jsonEncode(repostedEvent!.toJson().last) : '',
      tags: [
        ...tags,
        ['p', eventReference.masterPubkey],
        ['k', kind.toString()],
        eventReference.toTag(),
      ],
    );
  }
}

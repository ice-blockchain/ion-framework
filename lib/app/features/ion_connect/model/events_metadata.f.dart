// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

part 'events_metadata.f.freezed.dart';

@freezed
class EventsMetadataEntity with IonConnectEntity, ImmutableEntity, _$EventsMetadataEntity {
  const factory EventsMetadataEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required EventsMetadataData data,
  }) = _EventsMetadataEntity;

  const EventsMetadataEntity._();

  factory EventsMetadataEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return EventsMetadataEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.pubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: EventsMetadataData.fromEventMessage(eventMessage),
    );
  }

  static const int kind = 21750;
}

@freezed
class EventsMetadataData with _$EventsMetadataData implements EventSerializable {
  const factory EventsMetadataData({
    required List<EventReference> eventReferences,
    required EventMessage metadata,
  }) = _EventsMetadataData;

  const EventsMetadataData._();

  factory EventsMetadataData.fromEventMessage(EventMessage eventMessage) {
    return EventsMetadataData(
      eventReferences: eventMessage.tags
          .where(
            (tag) =>
                tag[0] == ReplaceableEventReference.tagName ||
                tag[0] == ImmutableEventReference.tagName,
          )
          .map(EventReference.fromTag)
          .toList(),
      metadata:
          EventMessage.fromPayloadJson(jsonDecode(eventMessage.content) as Map<String, dynamic>),
    );
  }

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/ICIP-01.md#special-ephemeral-event-for-embedding-other-non-ephemeral-events
  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) {
    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt,
      kind: EventsMetadataEntity.kind,
      content: jsonEncode(metadata.toJson().last),
      tags: [
        ...tags,
        ...eventReferences.map((eventReference) => eventReference.toTag()),
      ],
    );
  }

  EventReference? get metadataEventReference {
    // TODO: Handle cases other than `p` tag
    final tags = groupBy(metadata.tags, (tag) => tag[0]);
    final kind = metadata.kind;
    final masterPubkey = tags['p']?.first[1];
    if (masterPubkey == null) {
      return null;
    }

    return ReplaceableEventReference(
      masterPubkey: masterPubkey,
      kind: kind,
    );
  }
}

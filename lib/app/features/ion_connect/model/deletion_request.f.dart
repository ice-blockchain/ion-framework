// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/deletable_event.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/services/logger/logger.dart';

part 'deletion_request.f.freezed.dart';

@Freezed(equal: false)
class DeletionRequestEntity with IonConnectEntity, ImmutableEntity, _$DeletionRequestEntity {
  const factory DeletionRequestEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required DeletionRequest data,
    EventMessage? eventMessage,
  }) = _DeletionRequestEntity;

  const DeletionRequestEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/09.md
  factory DeletionRequestEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    if (eventMessage.sig == null) {
      Logger.log('Event message ${eventMessage.id} does not have a signature');
    }

    return DeletionRequestEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig ?? '',
      createdAt: eventMessage.createdAt,
      data: DeletionRequest.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  static const int kind = 5;
}

@freezed
class DeletionRequest with _$DeletionRequest implements EventSerializable {
  const factory DeletionRequest({required List<DeletableEvent> events}) = _DeletionRequest;

  const DeletionRequest._();

  factory DeletionRequest.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    final immutableEventIds = tags[ImmutableEventReference.tagName] ?? [];
    final immutableEventKinds = tags['k'] ?? [];

    if (immutableEventIds.length != immutableEventKinds.length) {
      throw IncorrectEventTagException(tag: tags);
    }

    final replaceableEvents = tags[ReplaceableEventReference.tagName] ?? [];

    final allEventReferences = [
      for (int i = 0; i < immutableEventIds.length; i++)
        ImmutableEventReference(
          eventId: immutableEventIds[i].last,
          kind: int.parse(immutableEventKinds[i].last),
          masterPubkey: eventMessage.masterPubkey,
        ),
      ...replaceableEvents.map(ReplaceableEventReference.fromTag),
    ];

    return DeletionRequest(
      events: allEventReferences
          .map((eventReference) => EventToDelete(eventReference: eventReference))
          .toList(),
    );
  }

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
    String? masterPubkey,
  }) {
    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt,
      kind: DeletionRequestEntity.kind,
      content: '',
      tags: [
        ...tags,
        if (signer is NoPrivateSigner) MasterPubkeyTag(value: masterPubkey).toTag(),
        for (final event in events) ...event.toTags(),
      ],
    );
  }
}

@freezed
class EventToDelete with _$EventToDelete implements DeletableEvent {
  const factory EventToDelete({
    required EventReference eventReference,
  }) = _EventToDelete;

  const EventToDelete._();

  @override
  List<List<String>> toTags() {
    return switch (eventReference) {
      ReplaceableEventReference() => [eventReference.toTag()],
      final ImmutableEventReference immutableEventReference
          // kind is optional in ImmutableEventReference, but we need it here for the `k` tag
          when immutableEventReference.kind != null =>
        [
          [ImmutableEventReference.tagName, immutableEventReference.eventId],
          ['k', immutableEventReference.kind.toString()],
        ],
      _ => throw UnsupportedEventReference(eventReference),
    };
  }
}

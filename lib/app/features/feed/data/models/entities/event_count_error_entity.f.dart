// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

part 'event_count_error_entity.f.freezed.dart';

@Freezed(equal: false)
class EventCountErrorEntity with _$EventCountErrorEntity, IonConnectEntity, ImmutableEntity {
  const factory EventCountErrorEntity({
    required String id,
    required String pubkey,
    required String signature,
    required String masterPubkey,
    required int createdAt,
    required EventCountErrorData data,
    EventMessage? eventMessage,
  }) = _EventCountErrorEntity;

  const EventCountErrorEntity._();

  factory EventCountErrorEntity.fromEventMessage(
    EventMessage eventMessage,
  ) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    final data = EventCountErrorData.fromEventMessage(eventMessage);

    return EventCountErrorEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      signature: eventMessage.sig!,
      masterPubkey: eventMessage.masterPubkey,
      createdAt: eventMessage.createdAt,
      data: data,
      eventMessage: eventMessage,
    );
  }

  static const int kind = 7000;
}

@freezed
class EventCountErrorData with _$EventCountErrorData {
  const factory EventCountErrorData({
    required String status,
    required int expiration,
    required EventReference eventReference,
    required String pubkey,
    required String masterPubkey,
    required dynamic content,
  }) = _EventCountErrorData;

  const EventCountErrorData._();

  factory EventCountErrorData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    final status = tags['status']!.first[1];
    final expiration = int.parse(tags['expiration']!.first[1]);
    final eventId = tags['e']?.first[1];
    final pubkey = tags['p']!.first[1];
    final masterPubkey = tags[MasterPubkeyTag.tagName]!.first[1];

    final eventReference =
        eventId != null ? ImmutableEventReference(eventId: eventId, masterPubkey: pubkey) : null;

    if (eventReference == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    return EventCountErrorData(
      status: status,
      expiration: expiration,
      eventReference: eventReference,
      pubkey: pubkey,
      masterPubkey: masterPubkey,
      content: eventMessage.content,
    );
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

part 'not_authoritative_event.f.freezed.dart';

@Freezed(equal: false)
class NotAuthoritativeEvent with _$NotAuthoritativeEvent, IonConnectEntity, ImmutableEntity {
  const factory NotAuthoritativeEvent({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required NotAuthoritativeEventData data,
    EventMessage? eventMessage,
  }) = _NotAuthoritativeEvent;

  const NotAuthoritativeEvent._();

  factory NotAuthoritativeEvent.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return NotAuthoritativeEvent(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: NotAuthoritativeEventData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  static const int kind = 20002;
}

@freezed
class NotAuthoritativeEventData with _$NotAuthoritativeEventData implements EventSerializable {
  const factory NotAuthoritativeEventData({
    required List<String> pubkeys,
  }) = _NotAuthoritativeEventData;

  const NotAuthoritativeEventData._();

  factory NotAuthoritativeEventData.fromEventMessage(EventMessage eventMessage) {
    return NotAuthoritativeEventData(
      pubkeys: eventMessage.tags.where((tag) => tag[0] == 'p').map((tag) => tag[1]).toList(),
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
      kind: NotAuthoritativeEvent.kind,
      tags: [
        ...tags,
        ...pubkeys.map((pubkey) => ['p', pubkey]),
      ],
      content: '',
    );
  }
}

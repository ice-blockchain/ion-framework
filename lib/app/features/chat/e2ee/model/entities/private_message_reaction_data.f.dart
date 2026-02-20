// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/event_message.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

part 'private_message_reaction_data.f.freezed.dart';

@immutable
@Freezed(equal: false)
class PrivateMessageReactionEntity
    with IonConnectEntity, ImmutableEntity, _$PrivateMessageReactionEntity {
  const factory PrivateMessageReactionEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required int createdAt,
    required PrivateMessageReactionEntityData data,
    EventMessage? eventMessage,
  }) = _PrivateMessageReactionEntity;

  const PrivateMessageReactionEntity._();

  factory PrivateMessageReactionEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return PrivateMessageReactionEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      createdAt: eventMessage.createdAt,
      masterPubkey: eventMessage.masterPubkey,
      data: PrivateMessageReactionEntityData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  @override
  FutureOr<EventMessage> toEventMessage(EventSerializable data) {
    return data.toEventMessage(
      createdAt: createdAt,
      NoPrivateSigner(pubkey),
    );
  }

  static const int kind = 7;

  @override
  String get signature => '';
}

@freezed
class PrivateMessageReactionEntityData
    with _$PrivateMessageReactionEntityData
    implements EventSerializable {
  const factory PrivateMessageReactionEntityData({
    required String content,
    required ReplaceableEventReference reference,
    required String masterPubkey,
  }) = _PrivateMessageReactionEntityData;

  const PrivateMessageReactionEntityData._();

  factory PrivateMessageReactionEntityData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    final identifierTag = tags[ReplaceableEventReference.tagName]?.first;

    if (identifierTag == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    return PrivateMessageReactionEntityData(
      content: eventMessage.content,
      reference: ReplaceableEventReference.fromTag(identifierTag),
      masterPubkey: eventMessage.masterPubkey,
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
      kind: PrivateMessageReactionEntity.kind,
      content: content,
      tags: [
        ...tags,
        MasterPubkeyTag(value: masterPubkey).toTag(),
        reference.toTag(),
      ],
      createdAt: createdAt,
    );
  }
}

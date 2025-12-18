// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

part 'user_archive_entity.f.freezed.dart';

@freezed
class UserArchiveEntity with IonConnectEntity, ImmutableEntity, _$UserArchiveEntity {
  const factory UserArchiveEntity({
    required String id,
    required String pubkey,
    required int createdAt,
    required String masterPubkey,
    required UserArchiveEntityData data,
  }) = _UserArchiveEntity;

  const UserArchiveEntity._();

  factory UserArchiveEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return UserArchiveEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      createdAt: eventMessage.createdAt,
      masterPubkey: eventMessage.masterPubkey,
      data: UserArchiveEntityData.fromEventMessage(eventMessage),
    );
  }

  @override
  FutureOr<EventMessage> toEventMessage(EventSerializable data) {
    return data.toEventMessage(
      createdAt: createdAt,
      NoPrivateSigner(pubkey),
    );
  }

  static const int kind = 2175;

  @override
  String get signature => '';
}

@freezed
class UserArchiveEntityData with _$UserArchiveEntityData implements EventSerializable {
  const factory UserArchiveEntityData({
    required String content,
    required String masterPubkey,
    required List<String> archivedConversations,
  }) = _UserArchiveEntityData;

  const UserArchiveEntityData._();

  factory UserArchiveEntityData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    final archivedConversations =
        tags[ConversationIdentifier.tagName]?.map((tag) => tag[1]).toList() ?? [];

    return UserArchiveEntityData(
      content: eventMessage.content,
      masterPubkey: eventMessage.masterPubkey,
      archivedConversations: archivedConversations,
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
      content: content,
      kind: UserArchiveEntity.kind,
      tags: [
        MasterPubkeyTag(value: masterPubkey).toTag(),
        ...tags,
        ...archivedConversations.map((id) => ConversationIdentifier(value: id).toTag()),
      ],
      createdAt: createdAt,
    );
  }
}

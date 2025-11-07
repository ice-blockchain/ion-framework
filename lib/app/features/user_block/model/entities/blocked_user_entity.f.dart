// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

part 'blocked_user_entity.f.freezed.dart';

@freezed
class BlockedUserEntity with IonConnectEntity, ImmutableEntity, _$BlockedUserEntity {
  const factory BlockedUserEntity({
    required String id,
    required String pubkey,
    required int createdAt,
    required String masterPubkey,
    required BlockedUserEntityData data,
    EventMessage? eventMessage,
  }) = _BlockedUserEntity;

  const BlockedUserEntity._();

  factory BlockedUserEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return BlockedUserEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      createdAt: eventMessage.createdAt,
      masterPubkey: eventMessage.masterPubkey,
      data: BlockedUserEntityData.fromEventMessage(eventMessage),
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

  static const int kind = 1757;

  @override
  String get signature => '';
}

@freezed
class BlockedUserEntityData with _$BlockedUserEntityData implements EventSerializable {
  const factory BlockedUserEntityData({
    required String content,
    required String masterPubkey,
    required List<String> blockedMasterPubkeys,
  }) = _BlockedUserEntityData;

  const BlockedUserEntityData._();

  factory BlockedUserEntityData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    final blockedMasterPubkeys = tags[PubkeyTag.tagName]?.map((tag) => tag[1]).toList() ?? [];

    return BlockedUserEntityData(
      content: eventMessage.content,
      masterPubkey: eventMessage.masterPubkey,
      blockedMasterPubkeys: blockedMasterPubkeys,
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
      kind: BlockedUserEntity.kind,
      tags: [
        MasterPubkeyTag(value: masterPubkey).toTag(),
        ...tags,
        ...blockedMasterPubkeys.map((pubkey) => PubkeyTag(value: pubkey).toTag()),
      ],
      createdAt: createdAt,
    );
  }
}

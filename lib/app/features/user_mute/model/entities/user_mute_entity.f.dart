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

part 'user_mute_entity.f.freezed.dart';

@freezed
class UserMuteEntity with IonConnectEntity, ImmutableEntity, _$UserMuteEntity {
  const factory UserMuteEntity({
    required String id,
    required String pubkey,
    required int createdAt,
    required String masterPubkey,
    required UserMuteEntityData data,
  }) = _UserMuteEntity;

  const UserMuteEntity._();

  factory UserMuteEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return UserMuteEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      createdAt: eventMessage.createdAt,
      masterPubkey: eventMessage.masterPubkey,
      data: UserMuteEntityData.fromEventMessage(eventMessage),
    );
  }

  @override
  FutureOr<EventMessage> toEventMessage(EventSerializable data) {
    return data.toEventMessage(
      createdAt: createdAt,
      NoPrivateSigner(pubkey),
    );
  }

  static const int kind = 3175;

  @override
  String get signature => '';
}

@freezed
class UserMuteEntityData with _$UserMuteEntityData implements EventSerializable {
  const factory UserMuteEntityData({
    required String content,
    required String masterPubkey,
    required List<String> mutedMasterPubkeys,
  }) = _UserMuteEntityData;

  const UserMuteEntityData._();

  factory UserMuteEntityData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    final mutedMasterPubkeys = tags[PubkeyTag.tagName]?.map((tag) => tag[1]).toList() ?? [];

    return UserMuteEntityData(
      content: eventMessage.content,
      masterPubkey: eventMessage.masterPubkey,
      mutedMasterPubkeys: mutedMasterPubkeys,
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
      kind: UserMuteEntity.kind,
      tags: [
        MasterPubkeyTag(value: masterPubkey).toTag(),
        ...tags,
        ...mutedMasterPubkeys.map((masterPubkey) => PubkeyTag(value: masterPubkey).toTag()),
      ],
      createdAt: createdAt,
    );
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/authorization_tag.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/entity_expiration.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

part 'community_join_data.f.freezed.dart';

@freezed
class CommunityJoinEntity with _$CommunityJoinEntity, IonConnectEntity, ImmutableEntity {
  const factory CommunityJoinEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required CommunityJoinData data,
    EventMessage? eventMessage,
  }) = _CommunityJoinEntity;

  const CommunityJoinEntity._();

  factory CommunityJoinEntity.fromEventMessage(EventMessage eventMessage) {
    return CommunityJoinEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: CommunityJoinData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  // https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/ICIP-3000.md
  static const kind = 1750;
}

@freezed
class CommunityJoinData with _$CommunityJoinData implements EventSerializable {
  const factory CommunityJoinData({
    required String uuid,
    String? pubkey,
    String? auth,
    int? expiration,
  }) = _CommunityJoinData;

  const CommunityJoinData._();

  factory CommunityJoinData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    return CommunityJoinData(
      uuid: tags[ConversationIdentifier.tagName]!.map(ConversationIdentifier.fromTag).first.value,
      pubkey: tags[PubkeyTag.tagName]?.map(PubkeyTag.fromTag).first.value,
      auth: tags[AuthorizationTag.tagName]?.map(AuthorizationTag.fromTag).firstOrNull?.value,
      expiration: tags[EntityExpiration.tagName]?.map(EntityExpiration.fromTag).firstOrNull?.value,
    );
  }

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner eventSigner, {
    int? createdAt,
    List<List<String>> tags = const [],
  }) {
    return EventMessage.fromData(
      signer: eventSigner,
      createdAt: createdAt,
      kind: CommunityJoinEntity.kind,
      tags: [
        ...tags,
        ConversationIdentifier(value: uuid).toTag(),
        if (pubkey != null) PubkeyTag(value: pubkey).toTag(),
        if (auth != null) AuthorizationTag(value: auth!).toTag(),
        if (expiration != null) EntityExpiration(value: expiration!).toTag(),
      ],
      content: '',
    );
  }
}

// SPDX-License-Identifier: ice License 1.0
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

part 'community_ban_user_data.f.freezed.dart';

@Freezed(equal: false)
class CommunityBanUserEntity with _$CommunityBanUserEntity, IonConnectEntity, ImmutableEntity {
  const factory CommunityBanUserEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required CommunityBanUserData data,
    EventMessage? eventMessage,
  }) = _CommunityBanUserEntity;

  const CommunityBanUserEntity._();

  factory CommunityBanUserEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw Exception('Incorrect event kind ${eventMessage.kind}, expected $kind');
    }

    return CommunityBanUserEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: CommunityBanUserData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  // https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/ICIP-3000.md
  static const kind = 1752;
}

@Freezed(equal: false)
class CommunityBanUserData with _$CommunityBanUserData implements EventSerializable {
  const factory CommunityBanUserData({
    required String uuid,
    required String bannedPubkey,
  }) = _CommunityBanUserData;

  const CommunityBanUserData._();

  factory CommunityBanUserData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    return CommunityBanUserData(
      uuid: tags[ConversationIdentifier.tagName]!.map(ConversationIdentifier.fromTag).first.value,
      bannedPubkey:
          tags[ConversationIdentifier.tagName]!.map(ConversationIdentifier.fromTag).first.value,
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
      kind: CommunityBanUserEntity.kind,
      tags: [
        ...tags,
        ConversationIdentifier(value: uuid).toTag(),
      ],
      content: '',
    );
  }
}

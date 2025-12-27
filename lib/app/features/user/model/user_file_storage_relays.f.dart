// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';

part 'user_file_storage_relays.f.freezed.dart';

@Freezed(equal: false)
class UserFileStorageRelaysEntity
    with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$UserFileStorageRelaysEntity {
  const factory UserFileStorageRelaysEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required UserFileStorageRelaysData data,
    EventMessage? eventMessage,
  }) = _UserFileStorageRelaysEntity;

  const UserFileStorageRelaysEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/96.md
  factory UserFileStorageRelaysEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return UserFileStorageRelaysEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: UserFileStorageRelaysData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  List<String> get urls => data.list.map((relay) => relay.url).toList();

  static const int kind = 10096;
}

@freezed
class UserFileStorageRelaysData
    with _$UserFileStorageRelaysData
    implements EventSerializable, ReplaceableEntityData {
  const factory UserFileStorageRelaysData({
    required List<UserRelay> list,
  }) = _UserFileStorageRelaysData;

  const UserFileStorageRelaysData._();

  factory UserFileStorageRelaysData.fromEventMessage(EventMessage eventMessage) {
    return UserFileStorageRelaysData(
      list: [
        for (final tag in eventMessage.tags)
          if (tag[0] == 'r') UserRelay.fromTag(tag),
      ],
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
      kind: UserFileStorageRelaysEntity.kind,
      tags: [
        ...tags,
        ...list.map((relay) => relay.toTag()),
      ],
      content: '',
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: UserFileStorageRelaysEntity.kind,
      masterPubkey: pubkey,
    );
  }
}

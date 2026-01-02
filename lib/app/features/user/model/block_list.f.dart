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

part 'block_list.f.freezed.dart';

@Freezed(equal: false)
class BlockListEntity with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$BlockListEntity {
  const factory BlockListEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required BlockListData data,
    EventMessage? eventMessage,
  }) = _BlockListEntity;

  const BlockListEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/51.md#standard-lists
  factory BlockListEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return BlockListEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: BlockListData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  static const int kind = 10000;
}

@freezed
class BlockListData with _$BlockListData implements EventSerializable, ReplaceableEntityData {
  const factory BlockListData({
    required List<String> pubkeys,
  }) = _BlockListData;

  const BlockListData._();

  factory BlockListData.fromEventMessage(EventMessage eventMessage) {
    return BlockListData(
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
      kind: BlockListEntity.kind,
      tags: [
        ...tags,
        ...pubkeys.map((pubkey) => ['p', pubkey]),
      ],
      content: '',
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: BlockListEntity.kind,
      masterPubkey: pubkey,
    );
  }
}

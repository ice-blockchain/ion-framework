// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';

part 'mute_set.f.freezed.dart';

enum MuteSetType {
  chatConversations(dTagName: 'chat_conversations'),
  notInterested(dTagName: 'not_interested'),
  unknown(dTagName: 'unknown');

  const MuteSetType({required this.dTagName});

  final String dTagName;
}

@Freezed(equal: false)
class MuteSetEntity with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$MuteSetEntity {
  const factory MuteSetEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required MuteSetData data,
    EventMessage? eventMessage,
  }) = _MuteSetEntity;

  const MuteSetEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/51.md#sets
  factory MuteSetEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return MuteSetEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: MuteSetData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  static const int kind = 30007;
}

@freezed
class MuteSetData with _$MuteSetData implements EventSerializable, ReplaceableEntityData {
  const factory MuteSetData({
    required MuteSetType type,
    @Default('') String content,
    @Default([]) List<String> communityIds,
    @Default([]) List<String> masterPubkeys,
  }) = _MuteSetData;

  const MuteSetData._();

  factory MuteSetData.fromEventMessage(EventMessage eventMessage) {
    final typeName = eventMessage.tags
        .firstWhereOrNull((tag) => tag[0] == ReplaceableEventIdentifier.tagName)?[1];

    if (typeName == null) {
      throw Exception('MuteSet event should have `${ReplaceableEventIdentifier.tagName}` tag');
    }

    return MuteSetData(
      content: eventMessage.content,
      communityIds: eventMessage.tags.where((tag) => tag[0] == 'h').map((tag) => tag[1]).toList(),
      masterPubkeys: eventMessage.tags.where((tag) => tag[0] == 'p').map((tag) => tag[1]).toList(),
      type: MuteSetType.values.firstWhere(
        (type) => type.dTagName == typeName,
        orElse: () => MuteSetType.unknown,
      ),
    );
  }

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    int? createdAt,
    String content = '',
    List<List<String>> tags = const [],
  }) {
    return EventMessage.fromData(
      signer: signer,
      content: this.content,
      createdAt: createdAt,
      kind: MuteSetEntity.kind,
      tags: [
        ...tags,
        ReplaceableEventIdentifier(value: type.dTagName).toTag(),
        ...communityIds.map((id) => ['h', id]),
        ...masterPubkeys.map((pubkey) => ['p', pubkey]),
      ],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      masterPubkey: pubkey,
      dTag: type.dTagName,
      kind: MuteSetEntity.kind,
    );
  }
}

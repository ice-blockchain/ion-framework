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
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';

part 'interests.f.freezed.dart';

@Freezed(equal: false)
class InterestsEntity with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$InterestsEntity {
  const factory InterestsEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required InterestsData data,
    EventMessage? eventMessage,
  }) = _InterestsEntity;

  const InterestsEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/51.md#standard-lists
  factory InterestsEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return InterestsEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: InterestsData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  static const int kind = 10015;
}

@freezed
class InterestsData with _$InterestsData implements EventSerializable, ReplaceableEntityData {
  const factory InterestsData({
    required List<String> hashtags,
    required List<ReplaceableEventReference> interestSetRefs,
  }) = _InterestsData;

  const InterestsData._();

  factory InterestsData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    return InterestsData(
      interestSetRefs: tags[ReplaceableEventReference.tagName]
              ?.map(ReplaceableEventReference.fromTag)
              .toList() ??
          [],
      hashtags: eventMessage.tags.where((tag) => tag[0] == 't').map((tag) => tag[1]).toList(),
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
      kind: InterestsEntity.kind,
      tags: [
        ...tags,
        ...interestSetRefs.map((ref) => ref.toTag()),
        ...hashtags.map((hashtag) => ['t', hashtag]),
      ],
      content: '',
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: InterestsEntity.kind,
      masterPubkey: pubkey,
    );
  }
}

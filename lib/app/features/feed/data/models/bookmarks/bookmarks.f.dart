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

part 'bookmarks.f.freezed.dart';

@Freezed(equal: false)
class BookmarksEntity with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$BookmarksEntity {
  const factory BookmarksEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required BookmarksData data,
    EventMessage? eventMessage,
  }) = _BookmarksEntity;

  const BookmarksEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/51.md#standard-lists
  factory BookmarksEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return BookmarksEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: BookmarksData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  static const int kind = 10003;
}

@freezed
class BookmarksData with _$BookmarksData implements EventSerializable, ReplaceableEntityData {
  const factory BookmarksData({
    required List<EventReference> eventReferences,
  }) = _BookmarksData;

  const BookmarksData._();

  factory BookmarksData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final replaceableEventReferences =
        tags[ReplaceableEventReference.tagName]?.map(ReplaceableEventReference.fromTag).toList() ??
            [];
    final immutableEventReferences =
        tags[ImmutableEventReference.tagName]?.map(ImmutableEventReference.fromTag).toList() ?? [];
    return BookmarksData(
      eventReferences: [...replaceableEventReferences, ...immutableEventReferences],
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
      kind: BookmarksEntity.kind,
      tags: [
        ...tags,
        ...eventReferences.map((ref) => ref.toTag()),
      ],
      content: '',
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: BookmarksEntity.kind,
      masterPubkey: pubkey,
    );
  }
}

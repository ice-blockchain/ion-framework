// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/model/title_tag.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';

part 'bookmarks_set.f.freezed.dart';

enum BookmarksSetType {
  chats(dTagName: 'archived_conversations'),
  homeFeedCollections(dTagName: 'homefeed_collections'),
  homeFeedCollectionsAll(dTagName: 'homefeed_collections_all');

  const BookmarksSetType({required this.dTagName});

  final String dTagName;
}

@Freezed(equal: false)
class BookmarksSetEntity
    with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$BookmarksSetEntity {
  const factory BookmarksSetEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required BookmarksSetData data,
    EventMessage? eventMessage,
  }) = _BookmarksSetEntity;

  const BookmarksSetEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/51.md#sets
  factory BookmarksSetEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return BookmarksSetEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: BookmarksSetData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  static const int kind = 30003;
}

@freezed
class BookmarksSetData with _$BookmarksSetData implements EventSerializable, ReplaceableEntityData {
  const factory BookmarksSetData({
    required String type,
    required List<EventReference> eventReferences,
    @Default('') String content,
    @Default('') String title,
    @Default([]) List<String> communitiesIds,
  }) = _BookmarksSetData;

  const BookmarksSetData._();

  factory BookmarksSetData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final typeName = tags[ReplaceableEventIdentifier.tagName] != null
        ? ReplaceableEventIdentifier.fromTag(tags[ReplaceableEventIdentifier.tagName]!.first).value
        : null;

    if (typeName == null) {
      throw Exception('BookmarksSet event should have `${ReplaceableEventIdentifier.tagName}` tag');
    }

    return BookmarksSetData(
      content: eventMessage.content,
      title: tags[TitleTag.tagName] != null
          ? TitleTag.fromTag(tags[TitleTag.tagName]!.first).value
          : '',
      communitiesIds: tags[ConversationIdentifier.tagName]?.map((tag) => tag[1]).toList() ?? [],
      eventReferences: eventMessage.tags
          .where(
            (tag) =>
                tag[0] == ReplaceableEventReference.tagName ||
                tag[0] == ImmutableEventReference.tagName,
          )
          .map(EventReference.fromTag)
          .toList(),
      type: typeName,
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
      kind: BookmarksSetEntity.kind,
      tags: [
        ...tags,
        ReplaceableEventIdentifier(value: type).toTag(),
        TitleTag(value: title).toTag(),
        ...eventReferences.map((ref) => ref.toTag()),
        ...communitiesIds.map((id) => ConversationIdentifier(value: id).toTag()),
        if (type == BookmarksSetType.chats.dTagName) ['encrypted'],
      ],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      masterPubkey: pubkey,
      dTag: type,
      kind: BookmarksSetEntity.kind,
    );
  }
}

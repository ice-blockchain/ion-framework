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
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';

part 'user_relays.f.freezed.dart';

@Freezed(equal: false)
class UserRelaysEntity
    with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$UserRelaysEntity
    implements DbCacheableEntity {
  const factory UserRelaysEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required UserRelaysData data,
    EventMessage? eventMessage,
  }) = _UserRelaysEntity;

  const UserRelaysEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/65.md
  factory UserRelaysEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return UserRelaysEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: UserRelaysData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  @override
  FutureOr<EventMessage> toEntityEventMessage() => eventMessage ?? toEventMessage(data);

  List<String> get urls => data.list.map((relay) => relay.url).toList();

  static const int kind = 10002;
}

@freezed
class UserRelaysData with _$UserRelaysData implements EventSerializable, ReplaceableEntityData {
  const factory UserRelaysData({
    required List<UserRelay> list,
  }) = _UserRelaysData;

  const UserRelaysData._();

  factory UserRelaysData.fromEventMessage(EventMessage eventMessage) {
    return UserRelaysData(
      list: [
        for (final tag in eventMessage.tags)
          if (tag[0] == UserRelay.tagName) UserRelay.fromTag(tag),
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
      kind: UserRelaysEntity.kind,
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
      kind: UserRelaysEntity.kind,
      masterPubkey: pubkey,
    );
  }
}

@freezed
class UserRelay with _$UserRelay {
  const factory UserRelay({
    required String url,
    @Default(true) bool read,
    @Default(true) bool write,
  }) = _UserRelay;

  const UserRelay._();

  factory UserRelay.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    return UserRelay(
      url: tag[1],
      read: tag.length == 2 || tag[2] == 'read',
      write: tag.length == 2 || tag[2] == 'write',
    );
  }

  factory UserRelay.fromJson(Map<String, String> json) {
    final url = json['url'];
    if (url == null) {
      throw const FormatException('Missing field: url');
    }
    final type = json['type'];
    return UserRelay(
      url: url,
      read: type != 'write',
      write: type != 'read',
    );
  }

  List<String> toTag() {
    final tag = [tagName, url];
    if (read && !write) {
      tag.add('read');
    } else if (write && !read) {
      tag.add('write');
    }
    return tag;
  }

  static const String tagName = 'r';
}

// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/community_join_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_request_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/reaction_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/feed/polls/models/poll_vote.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';

part 'event_count_result_data.f.freezed.dart';

enum EventCountResultType {
  replies,
  reposts,
  quotes,
  followers,
  reactions,
  members,
  pollVotes,
  stories,
  ugc,
}

@Freezed(equal: false)
class EventCountResultEntity
    with _$EventCountResultEntity, IonConnectEntity, ImmutableEntity, CacheableEntity {
  const factory EventCountResultEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required EventCountResultSummary data,
  }) = _EventCountResultEntity;

  const EventCountResultEntity._();

  /// https://github.com/nostr-protocol/nips/blob/vending-machine/90.md
  factory EventCountResultEntity.fromEventMessage(
    EventMessage eventMessage, {
    String? key,
  }) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    final data = EventCountResultData.fromEventMessage(eventMessage);
    final type = data.getType();
    final extractedKey = key ?? data.getKey(type);

    final summary = EventCountResultSummary(
      key: extractedKey,
      type: type,
      content: data.content,
      requestEventId: data.request.id,
    );

    final entity = EventCountResultEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: summary,
    );

    return entity;
  }

  @override
  String get cacheKey => cacheKeyBuilder(key: data.key, type: data.type);

  static String cacheKeyBuilder({required String key, required EventCountResultType type}) =>
      '$key:${type.toShortString()}';

  static const int kind = 6400;
}

@freezed
class EventCountResultSummary with _$EventCountResultSummary {
  const factory EventCountResultSummary({
    required dynamic content,
    required String key,
    required String requestEventId,
    required EventCountResultType type,
  }) = _EventCountResultSummary;
}

@freezed
class EventCountResultData with _$EventCountResultData {
  const factory EventCountResultData({
    required EventCountRequestEntity request,
    required dynamic content,
    required EventReference eventReference,
    required String pubkey,
  }) = _EventCountResultData;

  const EventCountResultData._();

  factory EventCountResultData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final pubkey = tags['p']!.first[1];
    final eventRef = tags['a']?.first[1];
    final eventId = tags['e']?.first[1];
    final request = EventCountRequestEntity.fromEventMessage(
      EventMessage.fromPayloadJson(jsonDecode(tags['request']!.first[1]) as Map<String, dynamic>),
    );

    final eventReference = eventRef != null
        ? ReplaceableEventReference.fromString(eventRef)
        : eventId != null
            ? ImmutableEventReference(eventId: eventId, masterPubkey: pubkey)
            : null;

    if (eventReference == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    return EventCountResultData(
      content: jsonDecode(eventMessage.content),
      request: request,
      eventReference: eventReference,
      pubkey: pubkey,
    );
  }

  EventCountResultType getType() {
    final EventCountRequestData(:filters, :params) = request.data;
    final filter = filters.first;
    if (filter.kinds != null &&
        (filter.kinds!.contains(GenericRepostEntity.kind) ||
            filter.kinds!.contains(RepostEntity.kind))) {
      return EventCountResultType.reposts;
    } else if (filter.kinds != null && filter.kinds!.contains(ReactionEntity.kind)) {
      return EventCountResultType.reactions;
    } else if (filter.kinds != null && filter.kinds!.contains(FollowListEntity.kind)) {
      return EventCountResultType.followers;
    } else if (filter.kinds != null && filter.kinds!.contains(PollVoteEntity.kind)) {
      return EventCountResultType.pollVotes;
    } else if (filter.tags != null &&
        (filter.tags!.containsKey('#a') || filter.tags!.containsKey('#e'))) {
      return EventCountResultType.replies;
    } else if (filter.tags != null && filter.tags!.containsKey('#q')) {
      return EventCountResultType.quotes;
    } else if (filter.kinds != null && filter.kinds!.contains(CommunityJoinEntity.kind)) {
      return EventCountResultType.members;
    } else if (filter.kinds != null &&
        filter.kinds!.contains(ModifiablePostEntity.kind) &&
        filter.search != null &&
        filter.search!.contains(ExpirationSearchExtension(expiration: true).query)) {
      return EventCountResultType.stories;
    } else if (filter.kinds != null &&
        filter.kinds!.contains(PostEntity.kind) &&
        filter.kinds!.contains(ModifiablePostEntity.kind) &&
        filter.kinds!.contains(ArticleEntity.kind) &&
        filter.search != null &&
        filter.search!.contains('expiration:false')) {
      return EventCountResultType.ugc;
    } else {
      throw UnknownEventCountResultType(eventReference);
    }
  }

  String getKey(EventCountResultType type) {
    final filter = request.data.filters.first;

    final qTag = filter.tags?['#q'];
    final pTag = filter.tags?['#p'];
    final eTag = filter.tags?['#e'];
    final aTag = filter.tags?['#a'];
    final authors = filter.authors;

    final key = switch (type) {
      EventCountResultType.stories when authors != null && authors.isNotEmpty => authors.first,
      EventCountResultType.ugc when authors != null && authors.isNotEmpty => authors.first,
      EventCountResultType.quotes =>
        qTag != null && qTag.isNotEmpty ? (qTag.first! as List<dynamic>).first : null,
      EventCountResultType.followers =>
        pTag != null && pTag.isNotEmpty ? (pTag.first! as List<dynamic>).first : null,
      EventCountResultType.pollVotes when aTag != null && aTag.isNotEmpty =>
        aTag.first is List ? (aTag.first! as List<dynamic>).first : aTag.first!,
      _ when eTag != null => eTag.isNotEmpty ? (eTag.first! as List<dynamic>).first : null,
      _ when aTag != null => aTag.isNotEmpty ? (aTag.first! as List<dynamic>).first : null,
      _ => null
    } as String?;

    if (key == null) {
      throw UnknownEventCountResultKey(eventReference);
    }

    return key;
  }
}

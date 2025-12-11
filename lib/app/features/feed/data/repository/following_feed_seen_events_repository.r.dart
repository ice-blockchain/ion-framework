// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/dao/seen_events_dao.m.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/dao/seen_reposts_dao.m.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/following_feed_database.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_modifier.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'following_feed_seen_events_repository.r.g.dart';

typedef EventPointer = ({EventReference eventReference, int createdAt});

@Riverpod(keepAlive: true)
FollowingFeedSeenEventsRepository followingFeedSeenEventsRepository(Ref ref) =>
    FollowingFeedSeenEventsRepository(
      seenEventsDao: ref.watch(seenEventsDaoProvider),
      seenRepostsDao: ref.watch(seenRepostsDaoProvider),
    );

class FollowingFeedSeenEventsRepository {
  FollowingFeedSeenEventsRepository({
    required SeenEventsDao seenEventsDao,
    required SeenRepostsDao seenRepostsDao,
  })  : _seenEventsDao = seenEventsDao,
        _seenRepostsDao = seenRepostsDao;

  final SeenEventsDao _seenEventsDao;
  final SeenRepostsDao _seenRepostsDao;

  Future<void> save(
    IonConnectEntity entity, {
    required FeedType feedType,
    FeedModifier? feedModifier,
  }) async {
    final kind = switch (entity) {
      ArticleEntity() => ArticleEntity.kind,
      ModifiablePostEntity() => ModifiablePostEntity.kind,
      PostEntity() => PostEntity.kind,
      CommunityTokenDefinitionEntity() => CommunityTokenDefinitionEntity.kind,
      CommunityTokenActionEntity() => CommunityTokenActionEntity.kind,
      GenericRepostEntity() => GenericRepostEntity.kind,
      RepostEntity() => RepostEntity.kind,
      _ => throw UnsupportedEntityType(entity),
    };

    return _seenEventsDao.insert(
      SeenEvent(
        eventReference: entity.toEventReference(),
        createdAt: entity.createdAt,
        feedType: feedType,
        feedModifier: feedModifier,
        pubkey: entity.masterPubkey,
        kind: kind,
      ),
    );
  }

  Future<void> setNextEvent({
    required EventReference eventReference,
    required EventReference nextEventReference,
    required FeedType feedType,
    FeedModifier? feedModifier,
  }) async {
    return _seenEventsDao.updateNextEvent(
      eventReference: eventReference,
      feedType: feedType,
      feedModifier: feedModifier,
      nextEventReference: nextEventReference,
    );
  }

  Future<EventPointer?> getSeenSequenceEnd({
    required EventReference eventReference,
    required FeedType feedType,
    FeedModifier? feedModifier,
  }) async {
    final seenEvent = await _seenEventsDao.getByReferenceForFeed(
      eventReference: eventReference,
      feedType: feedType,
      feedModifier: feedModifier,
    );

    if (seenEvent == null) return null;
    if (seenEvent.nextEventReference == null) {
      return _getEventPointer(seenEvent);
    }

    final seenSequenceEnd = await _seenEventsDao.getFirstWithoutNext(
      since: seenEvent.createdAt,
      feedType: feedType,
      feedModifier: feedModifier,
    );

    if (seenSequenceEnd == null) {
      return _getEventPointer(seenEvent);
    }

    return _getEventPointer(seenSequenceEnd);
  }

  Future<List<EventPointer>> getEventReferences({
    required FeedType feedType,
    required int limit,
    List<EventReference>? excludeReferences,
    List<String>? pubkeys,
    int? since,
    int? until,
    FeedModifier? feedModifier,
    bool groupByPubkey = false,
  }) async {
    final seenEvents = await (groupByPubkey
        ? _seenEventsDao.getGroupedByPubkeyEvents(
            feedType: feedType,
            feedModifier: feedModifier,
            excludeReferences: excludeReferences,
            pubkeys: pubkeys,
            limit: limit,
            since: since,
            until: until,
          )
        : _seenEventsDao.getEvents(
            feedType: feedType,
            feedModifier: feedModifier,
            excludeReferences: excludeReferences,
            pubkeys: pubkeys,
            limit: limit,
            since: since,
            until: until,
          ));
    return seenEvents.map(_getEventPointer).toList();
  }

  Stream<List<EventPointer>> watch({
    Iterable<EventReference>? eventsReferences,
    FeedType? feedType,
    FeedModifier? feedModifier,
  }) {
    final seenEventsStream = _seenEventsDao.watch(
      eventsReferences: eventsReferences,
      feedType: feedType,
      feedModifier: feedModifier,
    );
    return seenEventsStream.map(
      (eventsList) => eventsList.map(_getEventPointer).toList(),
    );
  }

  Future<void> deleteEvents({
    required FeedType feedType,
  }) async {
    await _seenEventsDao.deleteEvents(
      feedType: feedType,
    );
  }

  Future<void> saveSeenRepostedEvent(EventReference eventReference) async {
    return _seenRepostsDao.insert(
      SeenRepost(
        repostedEventReference: eventReference,
        seenAt: DateTime.now().microsecondsSinceEpoch,
      ),
    );
  }

  Future<DateTime?> getRepostedEventSeenAt(EventReference eventReference) async {
    final seenRepost = await _seenRepostsDao.getByRepostedReference(eventReference);
    if (seenRepost == null) return null;
    return DateTime.fromMicrosecondsSinceEpoch(seenRepost.seenAt);
  }

  /// Returns a map of pubkeys to the list of created_at timestamps for the last
  /// `maxUserEvents` events created by each user.
  Future<Map<String, List<int>>> getUsersCreatedContentTime({
    required int maxUserEvents,
  }) async {
    return _seenEventsDao.getUsersCreatedContentTime(maxUserEvents: maxUserEvents);
  }

  Future<bool> isSeen({required EventReference eventReference}) async {
    final seenEvent = await _seenEventsDao.getByReference(eventReference: eventReference);
    return seenEvent != null;
  }

  EventPointer _getEventPointer(SeenEvent seenEvent) {
    final eventReference = seenEvent.eventReference;

    if (eventReference is ImmutableEventReference && seenEvent.kind != null) {
      return (
        eventReference: eventReference.copyWith(kind: seenEvent.kind),
        createdAt: seenEvent.createdAt
      );
    }

    return (eventReference: eventReference, createdAt: seenEvent.createdAt);
  }
}

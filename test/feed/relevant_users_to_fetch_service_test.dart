// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/feed/data/models/feed_modifier.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/data/models/user_fetch_state.dart';
import 'package:ion/app/features/feed/data/repository/following_feed_seen_events_repository.r.dart';
import 'package:ion/app/features/feed/providers/relevant_users_to_fetch_service.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

void main() {
  group('RelevantUsersToFetchService', () {
    final now = DateTime(2025, 7, 7, 12);
    final user1 = UserFetchState(
      pubkey: 'user1',
      lastFetchTime: now.subtract(const Duration(hours: 2)),
    );
    final user2 = UserFetchState(
      pubkey: 'user2',
      emptyFetchCount: 1,
      lastFetchTime: now.subtract(const Duration(hours: 2)),
    );
    final user3 = UserFetchState(
      pubkey: 'user3',
    );

    test('returns users sorted by score (highest first)', () async {
      final fetchStateRepository = FakeUserFetchRepository([user1, user2, user3]);
      final seenEventsRepository = FakeFollowingFeedSeenEventsRepository({});
      final service = RelevantUsersToFetchService(
        fetchStatesRepository: fetchStateRepository,
        seenEventsRepository: seenEventsRepository,
      );
      final result = await service.getRelevantUsersToFetch(
        ['user1', 'user2', 'user3'],
        feedType: FeedType.post,
        limit: 3,
      );
      expect(result.length, 3);
      // user3 has never been fetched, so should have the highest score
      expect(result.first.state.pubkey, 'user3');
      // user1 and user2 are sorted by score
      expect(result.map((e) => e.state.pubkey), containsAll(['user1', 'user2', 'user3']));
    });

    test('respects the limit', () async {
      final fetchStateRepository = FakeUserFetchRepository([user1, user2, user3]);
      final seenEventsRepository = FakeFollowingFeedSeenEventsRepository({});
      final service = RelevantUsersToFetchService(
        fetchStatesRepository: fetchStateRepository,
        seenEventsRepository: seenEventsRepository,
      );
      final result = await service.getRelevantUsersToFetch(
        ['user1', 'user2', 'user3'],
        feedType: FeedType.post,
        limit: 2,
      );
      expect(result.length, 2);
    });

    test('filters by pubkeys', () async {
      final fetchStateRepository = FakeUserFetchRepository([user1, user2, user3]);
      final seenEventsRepository = FakeFollowingFeedSeenEventsRepository({});
      final service = RelevantUsersToFetchService(
        fetchStatesRepository: fetchStateRepository,
        seenEventsRepository: seenEventsRepository,
      );
      final result = await service.getRelevantUsersToFetch(
        ['user1', 'user2'],
        feedType: FeedType.post,
        limit: 5,
      );
      expect(result.length, 2);
      expect(result.map((e) => e.state.pubkey), containsAll(['user1', 'user2']));
    });

    test('user with higher emptyFetchCount has lower score', () async {
      final userWithNoRetries = UserFetchState(
        pubkey: 'user1',
        emptyFetchCount: 3,
        lastFetchTime: now.subtract(const Duration(hours: 5)),
      );
      final userWithRetries = UserFetchState(
        pubkey: 'user2',
        emptyFetchCount: 2,
        lastFetchTime: now.subtract(const Duration(hours: 5)),
      );
      final fetchStateRepository = FakeUserFetchRepository([userWithNoRetries, userWithRetries]);
      final seenEventsRepository = FakeFollowingFeedSeenEventsRepository({});
      final service = RelevantUsersToFetchService(
        fetchStatesRepository: fetchStateRepository,
        seenEventsRepository: seenEventsRepository,
      );
      final result = await service.getRelevantUsersToFetch(
        ['user1', 'user2'],
        feedType: FeedType.post,
        limit: 2,
      );
      expect(result.first.state.pubkey, 'user2');
      expect(result.last.state.pubkey, 'user1');
    });

    test('user with more recent lastFetchTime has lower score', () async {
      final userOlderFetch = UserFetchState(
        pubkey: 'user1',
        lastFetchTime: now.subtract(const Duration(hours: 10)),
      );
      final userRecentFetch = UserFetchState(
        pubkey: 'user2',
        lastFetchTime: now.subtract(const Duration(hours: 1)),
      );
      final fetchStateRepository = FakeUserFetchRepository([userOlderFetch, userRecentFetch]);
      final seenEventsRepository = FakeFollowingFeedSeenEventsRepository({});
      final service = RelevantUsersToFetchService(
        fetchStatesRepository: fetchStateRepository,
        seenEventsRepository: seenEventsRepository,
      );
      final result = await service.getRelevantUsersToFetch(
        ['user1', 'user2'],
        feedType: FeedType.post,
        limit: 2,
      );
      expect(result.first.state.pubkey, 'user1');
      expect(result.last.state.pubkey, 'user2');
    });

    test('user with more frequent content has higher score', () async {
      final now = DateTime(2025, 7, 7, 12);
      final userFrequent = UserFetchState(
        pubkey: 'user1',
        lastFetchTime: now.subtract(const Duration(hours: 10)),
      );
      final userRare = UserFetchState(
        pubkey: 'user2',
        lastFetchTime: now.subtract(const Duration(hours: 10)),
      );
      final fetchStateRepository = FakeUserFetchRepository([userFrequent, userRare]);
      // user1 has more content timestamps (more frequent content)
      final seenEventsRepository = FakeFollowingFeedSeenEventsRepository({
        'user1': [
          now.subtract(const Duration(hours: 1)).microsecondsSinceEpoch,
          now.subtract(const Duration(hours: 2)).microsecondsSinceEpoch,
        ],
        'user2': [
          now.subtract(const Duration(hours: 2)).microsecondsSinceEpoch,
          now.subtract(const Duration(hours: 4)).microsecondsSinceEpoch,
        ],
      });
      final service = RelevantUsersToFetchService(
        fetchStatesRepository: fetchStateRepository,
        seenEventsRepository: seenEventsRepository,
      );
      final result = await service.getRelevantUsersToFetch(
        ['user1', 'user2'],
        feedType: FeedType.post,
        limit: 2,
      );
      expect(result.first.state.pubkey, 'user1');
      expect(result.last.state.pubkey, 'user2');
    });

    test(
      'user with unknown frequency (only 1 event) has lower score comparing to a user with frequent content',
      () async {
        final now = DateTime(2025, 7, 7, 12);
        final userFrequent = UserFetchState(
          pubkey: 'user1',
          lastFetchTime: now.subtract(const Duration(hours: 10)),
        );
        final userUnknown = UserFetchState(
          pubkey: 'user2',
          lastFetchTime: now.subtract(const Duration(hours: 10)),
        );
        final fetchStateRepository = FakeUserFetchRepository([userFrequent, userUnknown]);
        // user1 has 3 events (frequent), user2 has only 1 event (unknown frequency)
        final seenEventsRepository = FakeFollowingFeedSeenEventsRepository({
          'user2': [
            now.subtract(const Duration(hours: 2)).microsecondsSinceEpoch,
          ],
          'user1': [
            now.subtract(const Duration(hours: 1)).microsecondsSinceEpoch,
            now.subtract(const Duration(hours: 2)).microsecondsSinceEpoch,
            now.subtract(const Duration(hours: 3)).microsecondsSinceEpoch,
          ],
        });
        final service = RelevantUsersToFetchService(
          fetchStatesRepository: fetchStateRepository,
          seenEventsRepository: seenEventsRepository,
        );
        final result = await service.getRelevantUsersToFetch(
          ['user1', 'user2'],
          feedType: FeedType.post,
          limit: 2,
        );
        expect(result.first.state.pubkey, 'user1');
        expect(result.last.state.pubkey, 'user2');
      },
    );
    test('user with irregular posting frequency is handled', () async {
      final now = DateTime(2025, 7, 7, 12);
      final userIrregular = UserFetchState(
        pubkey: 'user1',
        lastFetchTime: now.subtract(const Duration(hours: 10)),
      );
      final userRegular = UserFetchState(
        pubkey: 'user2',
        lastFetchTime: now.subtract(const Duration(hours: 10)),
      );
      final fetchStateRepository = FakeUserFetchRepository([userIrregular, userRegular]);
      final seenEventsRepository = FakeFollowingFeedSeenEventsRepository({
        'user1': [
          now.subtract(const Duration(hours: 1)).microsecondsSinceEpoch,
          now.subtract(const Duration(hours: 5)).microsecondsSinceEpoch,
          now.subtract(const Duration(hours: 10)).microsecondsSinceEpoch,
        ],
        'user2': [
          now.subtract(const Duration(hours: 2)).microsecondsSinceEpoch,
          now.subtract(const Duration(hours: 4)).microsecondsSinceEpoch,
          now.subtract(const Duration(hours: 6)).microsecondsSinceEpoch,
        ],
      });
      final service = RelevantUsersToFetchService(
        fetchStatesRepository: fetchStateRepository,
        seenEventsRepository: seenEventsRepository,
      );
      final result = await service.getRelevantUsersToFetch(
        ['user1', 'user2'],
        feedType: FeedType.post,
        limit: 2,
      );
      // user2 is more regular, so should be ranked higher
      expect(result.first.state.pubkey, 'user2');
      expect(result.last.state.pubkey, 'user1');
    });
  });
}

class FakeUserFetchRepository implements UsersFetchStatesRepository {
  FakeUserFetchRepository(this.states);
  List<UserFetchState> states;

  @override
  Future<void> save(
    String pubkey, {
    required FeedType feedType,
    required bool hasContent,
    FeedModifier? feedModifier,
  }) async {}

  @override
  Future<List<UserFetchState>> select({
    required List<String> pubkeys,
    required FeedType feedType,
    FeedModifier? feedModifier,
  }) async {
    return states.where((s) => pubkeys.contains(s.pubkey)).toList();
  }
}

class FakeFollowingFeedSeenEventsRepository implements FollowingFeedSeenEventsRepository {
  FakeFollowingFeedSeenEventsRepository(this.times);

  Map<String, List<int>> times;

  @override
  Future<void> deleteEvents({
    required FeedType feedType,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<({EventReference eventReference, int createdAt})>> getEventReferences({
    required FeedType feedType,
    required int limit,
    List<EventReference>? excludeReferences,
    List<String>? pubkeys,
    int? since,
    int? until,
    FeedModifier? feedModifier,
    bool groupByPubkey = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DateTime?> getRepostedEventSeenAt(EventReference eventReference) {
    throw UnimplementedError();
  }

  @override
  Future<({int createdAt, EventReference eventReference})?> getSeenSequenceEnd({
    required EventReference eventReference,
    required FeedType feedType,
    FeedModifier? feedModifier,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, List<int>>> getUsersCreatedContentTime({required int maxUserEvents}) async {
    return times;
  }

  @override
  Future<void> save(
    IonConnectEntity entity, {
    required FeedType feedType,
    FeedModifier? feedModifier,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveSeenRepostedEvent(EventReference eventReference) {
    throw UnimplementedError();
  }

  @override
  Future<void> setNextEvent({
    required EventReference eventReference,
    required EventReference nextEventReference,
    required FeedType feedType,
    FeedModifier? feedModifier,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<({int createdAt, EventReference eventReference})>> watch({
    Iterable<EventReference>? eventsReferences,
    FeedType? feedType,
    FeedModifier? feedModifier,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isSeen({required EventReference eventReference}) {
    throw UnimplementedError();
  }
}

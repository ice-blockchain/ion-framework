// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/feed_modifier.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/data/repository/following_feed_seen_events_repository.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

abstract class FeedSortingStrategy {
  bool shouldApply({
    required FeedType feedType,
    required FeedModifier? feedModifier,
  });

  Future<Set<IonConnectEntity>> sort({
    required Ref ref,
    required Set<IonConnectEntity> items,
    required FeedType feedType,
    required FeedModifier? feedModifier,
  });
}

class TrendingVideoSortingStrategy implements FeedSortingStrategy {
  const TrendingVideoSortingStrategy({
    this.watchedVideosLimit = 100,
  });

  final int watchedVideosLimit;

  @override
  bool shouldApply({
    required FeedType feedType,
    required FeedModifier? feedModifier,
  }) {
    return feedType == FeedType.video && feedModifier is FeedModifierTrending;
  }

  @override
  Future<Set<IonConnectEntity>> sort({
    required Ref ref,
    required Set<IonConnectEntity> items,
    required FeedType feedType,
    required FeedModifier? feedModifier,
  }) async {
    if (items.isEmpty) return items;

    final seenEventsRepository = ref.read(followingFeedSeenEventsRepositoryProvider);

    final watchedReferences = await seenEventsRepository.getEventReferences(
      feedType: feedType,
      feedModifier: feedModifier,
      limit: watchedVideosLimit,
    );

    final watchedReferenceSet = watchedReferences.map((ref) => ref.eventReference).toSet();

    final unwatchedVideos = <IonConnectEntity>[];
    final watchedVideos = <IonConnectEntity>[];

    for (final entity in items) {
      if (watchedReferenceSet.contains(entity.toEventReference())) {
        watchedVideos.add(entity);
      } else {
        unwatchedVideos.add(entity);
      }
    }

    return {...unwatchedVideos, ...watchedVideos};
  }
}

class FeedSortingManager {
  static final List<FeedSortingStrategy> _strategies = [
    const TrendingVideoSortingStrategy(),
  ];

  static Future<Set<IonConnectEntity>> getSortedItems({
    required Ref ref,
    required Set<IonConnectEntity> items,
    required FeedType feedType,
    required FeedModifier? feedModifier,
  }) async {
    if (items.isEmpty) return items;

    final strategy = _strategies.firstWhere(
      (s) => s.shouldApply(feedType: feedType, feedModifier: feedModifier),
      orElse: _NoOpSortingStrategy.new,
    );

    return strategy.sort(
      ref: ref,
      items: items,
      feedType: feedType,
      feedModifier: feedModifier,
    );
  }
}

class _NoOpSortingStrategy implements FeedSortingStrategy {
  @override
  bool shouldApply({
    required FeedType feedType,
    required FeedModifier? feedModifier,
  }) =>
      false;

  @override
  Future<Set<IonConnectEntity>> sort({
    required Ref ref,
    required Set<IonConnectEntity> items,
    required FeedType feedType,
    required FeedModifier? feedModifier,
  }) async =>
      items;
}

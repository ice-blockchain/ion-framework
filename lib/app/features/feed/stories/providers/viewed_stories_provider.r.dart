// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/data/repository/following_feed_seen_events_repository.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'viewed_stories_provider.r.g.dart';

@riverpod
class ViewedStories extends _$ViewedStories {
  @override
  Set<EventReference>? build() {
    final seenEventsRepository = ref.watch(followingFeedSeenEventsRepositoryProvider);
    final subscription = seenEventsRepository
        .watch(feedType: FeedType.story)
        .listen((seenEvents) => state = seenEvents.map((e) => e.eventReference).toSet());

    ref.onDispose(subscription.cancel);
    return null;
  }

  Future<void> markStoryAsViewed(IonConnectEntity storyEntity) async {
    final storyReference = storyEntity.toEventReference();
    final state = this.state ?? {};
    if (!state.contains(storyReference)) {
      final seenEventsRepository = ref.read(followingFeedSeenEventsRepositoryProvider);
      await seenEventsRepository.save(storyEntity, feedType: FeedType.story);
    }
  }
}

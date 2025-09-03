// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_filter.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_current_filter_provider.m.dart';
import 'package:ion/app/features/feed/providers/feed_following_content_provider.m.dart';
import 'package:ion/app/features/feed/providers/feed_for_you_content_provider.m.dart';
import 'package:ion/app/features/feed/stories/data/models/user_story.f.dart';
import 'package:ion/app/features/feed/stories/providers/current_user_feed_story_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_stories_provider.r.g.dart';

@riverpod
class FeedStories extends _$FeedStories with DelegatedPagedNotifier {
  @override
  ({Iterable<UserStory>? items, bool hasMore}) build() {
    final filter = ref.watch(feedCurrentFilterProvider);
    final currentUserStory = ref.watch(currentUserFeedStoryProvider);
    final data = switch (filter.filter) {
      FeedFilter.following => ref.watch(
          feedFollowingContentProvider(FeedType.story)
              .select((data) => (items: data.items, hasMore: data.hasMore)),
        ),
      FeedFilter.forYou => ref.watch(
          feedForYouContentProvider(FeedType.story)
              .select((data) => (items: data.items, hasMore: data.hasMore)),
        ),
    };

    final userStories = _userStories(data.items);
    final stories = {
      if (currentUserStory != null) currentUserStory,
      if (userStories != null) ...userStories,
    };

    return (items: stories, hasMore: data.hasMore);
  }

  @override
  PagedNotifier getDelegate() {
    final filter = ref.read(feedCurrentFilterProvider);
    return switch (filter.filter) {
      FeedFilter.following => ref.read(feedFollowingContentProvider(FeedType.story).notifier),
      FeedFilter.forYou => ref.read(feedForYouContentProvider(FeedType.story).notifier),
    };
  }

  @override
  void refresh() {
    getDelegate().refresh();
    final stories = state.items?.toList() ?? [];
    for (final story in stories) {
      ref.read(ionConnectCacheProvider.notifier).remove(
            EventCountResultEntity.cacheKeyBuilder(
              key: story.pubkey,
              type: EventCountResultType.stories,
            ),
          );
    }
  }

  Iterable<UserStory>? _userStories(Iterable<IonConnectEntity>? entities) {
    if (entities == null) return null;

    final postEntities =
        entities.whereType<ModifiablePostEntity>().where((post) => post.data.expiration != null);

    final userStoriesMap = <String, UserStory>{};

    for (final post in postEntities) {
      final pubkey = post.masterPubkey;

      final userStory = UserStory(
        pubkey: pubkey,
        story: post,
      );

      userStoriesMap[pubkey] = userStory;
    }

    return userStoriesMap.values;
  }
}

@riverpod
List<UserStory> feedStoriesByPubkey(Ref ref, String pubkey, {bool showOnlySelectedUser = false}) {
  final stories = ref.watch(feedStoriesProvider.select((state) => state.items?.toList() ?? []));
  final userIndex = stories.indexWhere((userStories) => userStories.pubkey == pubkey);

  if (userIndex == -1) return [];

  if (showOnlySelectedUser) {
    return [stories[userIndex]];
  } else {
    return stories.sublist(userIndex);
  }
}

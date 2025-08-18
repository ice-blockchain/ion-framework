// SPDX-License-Identifier: ice License 1.0

import 'package:async/async.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/data/models/feed_filter.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_current_filter_provider.m.dart';
import 'package:ion/app/features/feed/providers/feed_following_content_provider.m.dart';
import 'package:ion/app/features/feed/providers/feed_for_you_content_provider.m.dart';
import 'package:ion/app/features/feed/providers/feed_posts_provider.r.dart';
import 'package:ion/app/features/feed/providers/repost_notifier.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_videos_provider.r.g.dart';

@riverpod
class FeedVideos extends _$FeedVideos with DelegatedPagedNotifier {
  @override
  ({Iterable<IonConnectEntity>? items, bool hasMore}) build() {
    // final postsStream = ref.watch(createPostNotifierStreamProvider);
    // final repostsStream = ref.watch(createRepostNotifierStreamProvider);
    // final subscription =
    //     StreamGroup.merge([postsStream, repostsStream]).distinct().listen(insertEntity);
    // ref.onDispose(subscription.cancel);

    final filter = ref.watch(feedCurrentFilterProvider.select((state) => state.filter));

    // Try getting videos from posts provider instead
    final postsData = switch (filter) {
      FeedFilter.following => ref.watch(
          feedFollowingContentProvider(FeedType.post)
              .select((data) => (items: data.items, hasMore: data.hasMore)),
        ),
      FeedFilter.forYou => ref.watch(
          feedForYouContentProvider(FeedType.post)
              .select((data) => (items: data.items, hasMore: data.hasMore)),
        ),
    };
    
    // Filter for videos only
    final videoItems = postsData.items?.where((entity) => 
      ref.read(isVideoPostProvider(entity)) || ref.read(isVideoRepostProvider(entity))
    );
    
    final data = (items: videoItems, hasMore: postsData.hasMore);

    // Trigger initial fetch if no data (commented out to prevent infinite loop)
    // if (data.items == null && data.hasMore) {
    //   Future.microtask(fetchEntities);
    // }

    print('🔥 [d3g] FeedVideos build filter: $filter');
    print('🔥 [d3g] FeedVideos build data: ${data.items?.length}');
    print('🔥 [d3g] FeedVideos build hasMore: ${data.hasMore}');

    return data;
  }

  @override
  Future<void> fetchEntities() async {
    print('🔥 [d3g] FeedVideos fetchEntities called');
    final result = await super.fetchEntities();
    final currentData = ref.read(feedVideosProvider);
    print('🔥 [d3g] FeedVideos fetchEntities completed, data length: ${currentData.items?.length}');
    return result;
  }

  @override
  PagedNotifier getDelegate() {
    final filter = ref.read(feedCurrentFilterProvider);
    final delegate = switch (filter.filter) {
      FeedFilter.following => ref.read(feedFollowingContentProvider(FeedType.video).notifier),
      FeedFilter.forYou => ref.read(feedForYouContentProvider(FeedType.video).notifier),
    };
    print('🔥 [d3g] FeedVideos getDelegate filter: ${filter.filter}, delegate: $delegate');
    return delegate;
  }
}

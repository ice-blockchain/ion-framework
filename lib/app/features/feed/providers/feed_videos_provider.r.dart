// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/feed_filter.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_current_filter_provider.m.dart';
import 'package:ion/app/features/feed/providers/feed_following_content_provider.m.dart';
import 'package:ion/app/features/feed/providers/feed_for_you_content_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_videos_provider.r.g.dart';

@riverpod
class FeedVideos extends _$FeedVideos with DelegatedPagedNotifier {
  @override
  ({Iterable<IonConnectEntity>? items, bool hasMore}) build() {
    final filter = ref.watch(feedCurrentFilterProvider);

    final data = switch (filter.filter) {
      FeedFilter.following => ref.watch(
          feedFollowingContentProvider(FeedType.video)
              .select((data) => (items: data.items, hasMore: data.hasMore)),
        ),
      FeedFilter.forYou => ref.watch(
          feedForYouContentProvider(FeedType.video)
              .select((data) => (items: data.items, hasMore: data.hasMore)),
        ),
    };

    return data;
  }

  @override
  PagedNotifier getDelegate() {
    final filter = ref.read(feedCurrentFilterProvider);
    return switch (filter.filter) {
      FeedFilter.following => ref.read(feedFollowingContentProvider(FeedType.video).notifier),
      FeedFilter.forYou => ref.read(feedForYouContentProvider(FeedType.video).notifier),
    };
  }
}

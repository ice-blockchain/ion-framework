// SPDX-License-Identifier: ice License 1.0

import 'package:async/async.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/create_article/providers/create_article_provider.r.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_category.dart';
import 'package:ion/app/features/feed/data/models/feed_filter.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_current_filter_provider.m.dart';
import 'package:ion/app/features/feed/providers/feed_following_content_provider.m.dart';
import 'package:ion/app/features/feed/providers/feed_for_you_content_provider.m.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/providers/repost_notifier.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_posts_provider.r.g.dart';

@riverpod
class FeedPosts extends _$FeedPosts with DelegatedPagedNotifier {
  @override
  ({Iterable<IonConnectEntity>? items, bool hasMore}) build() {
    final postsStream = ref.watch(createPostNotifierStreamProvider);
    final articlesStream = ref.watch(createArticleNotifierStreamProvider);
    final repostsStream = ref.watch(createRepostNotifierStreamProvider);
    final subscription = StreamGroup.merge([postsStream, articlesStream, repostsStream])
        .where(_filterEntities)
        .distinct()
        .listen(insertEntity);
    ref.onDispose(subscription.cancel);

    final filter = ref.watch(feedCurrentFilterProvider);
    final feedType = FeedType.fromCategory(filter.category);

    final data = switch (filter.filter) {
      FeedFilter.following => ref.watch(
          feedFollowingContentProvider(feedType)
              .select((data) => (items: data.items, hasMore: data.hasMore)),
        ),
      FeedFilter.forYou => ref.watch(
          feedForYouContentProvider(feedType)
              .select((data) => (items: data.items, hasMore: data.hasMore)),
        ),
    };

    return data;
  }

  @override
  PagedNotifier getDelegate() {
    final filter = ref.read(feedCurrentFilterProvider);
    final feedType = FeedType.fromCategory(filter.category);
    return switch (filter.filter) {
      FeedFilter.following => ref.read(feedFollowingContentProvider(feedType).notifier),
      FeedFilter.forYou => ref.read(feedForYouContentProvider(feedType).notifier),
    };
  }

  bool _filterEntities(IonConnectEntity entity) {
    final currentCategory = ref.read(feedCurrentFilterProvider).category;
    return switch (currentCategory) {
      FeedCategory.feed => _isRegularPostOrRepost(entity) || _isArticleOrArticleRepost(entity),
      FeedCategory.videos =>
        ref.read(isVideoPostProvider(entity)) || ref.read(isVideoRepostProvider(entity)),
      FeedCategory.articles => _isArticleOrArticleRepost(entity),
    };
  }

  bool _isRegularPostOrRepost(IonConnectEntity entity) {
    final isRegularPost = entity is ModifiablePostEntity &&
        entity.data.parentEvent?.eventReference == null &&
        entity.data.expiration == null;
    final isPostRepost = _isPostRepost(entity);
    return isRegularPost || isPostRepost;
  }

  bool _isPostRepost(IonConnectEntity entity) {
    final repostedEntity = ref.read(getRepostedEntityProvider(entity));
    return repostedEntity != null &&
        (repostedEntity is ModifiablePostEntity || repostedEntity is PostEntity);
  }

  bool _isArticleOrArticleRepost(IonConnectEntity entity) {
    return entity is ArticleEntity || _isArticleRepost(entity);
  }

  bool _isArticleRepost(IonConnectEntity entity) {
    final repostedEntity = ref.read(getRepostedEntityProvider(entity));
    return repostedEntity != null && repostedEntity is ArticleEntity;
  }
}

@riverpod
bool isVideoPost(Ref ref, IonConnectEntity entity) {
  if (entity is ModifiablePostEntity) {
    return entity.data.parentEvent?.eventReference == null &&
        entity.data.expiration == null &&
        entity.data.hasVideo;
  }
  return false;
}

@riverpod
bool isVideoReply(Ref ref, IonConnectEntity entity) {
  if (entity is ModifiablePostEntity) {
    return entity.data.parentEvent?.eventReference != null &&
        entity.data.expiration == null &&
        entity.data.hasVideo;
  }
  return false;
}

@riverpod
bool isVideoRepost(Ref ref, IonConnectEntity entity) {
  final reposted = ref.read(getRepostedEntityProvider(entity));
  if (reposted is ModifiablePostEntity) {
    return reposted.data.parentEvent?.eventReference == null &&
        reposted.data.expiration == null &&
        reposted.data.hasVideo;
  }
  return false;
}

@riverpod
IonConnectEntity? getRepostedEntity(Ref ref, IonConnectEntity entity) {
  EventReference? repostedEventReference;
  if (entity is GenericRepostEntity) {
    repostedEventReference = entity.data.eventReference;
  } else if (entity is RepostEntity) {
    repostedEventReference = entity.data.eventReference;
  }
  if (repostedEventReference == null) return null;
  return ref.read(ionConnectSyncEntityWithCountersProvider(eventReference: repostedEventReference));
}

@riverpod
class ExpandedPostsState extends _$ExpandedPostsState {
  @override
  Set<String> build() => {};

  bool isExpanded(IonConnectEntity entity) {
    return state.contains(entity.id);
  }

  void expand(IonConnectEntity entity) {
    state = {...state, entity.id};
  }

  void collapse(IonConnectEntity entity) {
    state = state.where((id) => id != entity.id).toSet();
  }
}

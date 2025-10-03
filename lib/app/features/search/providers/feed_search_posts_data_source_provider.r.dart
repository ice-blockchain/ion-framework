// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_category.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event_marker.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/search/model/advanced_search_category.dart';
import 'package:ion/app/features/search/model/feed_search_source.dart';
import 'package:ion/app/features/search/providers/feed_search_filter_relays_provider.r.dart';
import 'package:ion/app/features/search/providers/feed_search_filters_provider.m.dart';
import 'package:ion/app/features/user/model/interest_set.f.dart';
import 'package:ion/app/features/user/providers/relays/optimal_user_relays_provider.r.dart';
import 'package:ion/app/features/user/providers/user_interests_set_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_search_posts_data_source_provider.r.g.dart';

@riverpod
List<EntitiesDataSource>? feedSearchPostsDataSource(
  Ref ref, {
  required String query,
  required AdvancedSearchCategory category,
}) {
  // TODO:pass languages to the filters when defined
  // ignore: unused_local_variable
  final languageInterestSet =
      ref.watch(currentUserInterestsSetProvider(InterestSetType.languages)).valueOrNull;
  final filters = ref.watch(feedSearchFilterProvider);
  final filterRelayMasterPubkeys =
      ref.watch(feedSearchFilterRelayMasterPubkeysProvider(filters.source)).valueOrNull;
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);

  final isTagSearch = RelatedHashtag.isTag(query);

  final searchExtensions = [
    if (!isTagSearch) QuerySearchExtension(searchQuery: query),
    if (category == AdvancedSearchCategory.videos ||
        (!filters.categories[FeedCategory.feed].falseOrValue &&
            filters.categories[FeedCategory.videos].falseOrValue))
      VideosSearchExtension(contain: true),
    if (category == AdvancedSearchCategory.trending) TrendingSearchExtension(),
    if (category == AdvancedSearchCategory.top) TopSearchExtension(),
    if (category == AdvancedSearchCategory.photos) ImagesSearchExtension(contain: true),
  ];

  final tags = isTagSearch
      ? {
          '#${RelatedHashtag.tagName}': [
            query.toLowerCase(),
          ],
        }
      : <String, List<Object>>{};

  if (filterRelayMasterPubkeys != null && currentPubkey != null) {
    return [
      _buildSearchDataSource(
        actionSource: ActionSourceOptimalRelays(
          masterPubkeys: filterRelayMasterPubkeys,
          strategy: OptimalRelaysStrategy.mostUsers,
        ),
        authors: filters.source == FeedSearchSource.following ? filterRelayMasterPubkeys : null,
        filter: _buildFilter(
          authors: filters.source == FeedSearchSource.following ? filterRelayMasterPubkeys : null,
          currentPubkey: currentPubkey,
          tags: tags,
          searchExtensions: searchExtensions,
          includePosts: filters.categories[FeedCategory.feed].falseOrValue ||
              filters.categories[FeedCategory.videos].falseOrValue,
          includeArticles: filters.categories[FeedCategory.articles].falseOrValue,
        ),
      ),
    ];
  }
  return null;
}

EntitiesDataSource _buildSearchDataSource({
  required ActionSource actionSource,
  required List<String>? authors,
  required RequestFilter filter,
}) {
  return EntitiesDataSource(
    actionSource: actionSource,
    entityFilter: (entity) {
      if (authors != null && !authors.contains(entity.masterPubkey)) {
        return false;
      }

      return (entity is ModifiablePostEntity && entity.data.parentEvent == null) ||
          (entity is PostEntity && entity.data.parentEvent == null) ||
          entity is RepostEntity ||
          entity is GenericRepostEntity ||
          entity is ArticleEntity;
    },
    requestFilter: filter,
  );
}

RequestFilter _buildFilter({
  required List<String>? authors,
  required String currentPubkey,
  required bool includePosts,
  required bool includeArticles,
  Map<String, List<Object?>> tags = const {},
  List<SearchExtension> searchExtensions = const [],
}) {
  final search = SearchExtensions([
    ...searchExtensions,
    if (includePosts) ...[
      ...SearchExtensions.withCounters(currentPubkey: currentPubkey).extensions,
      ...SearchExtensions.withAuthors().extensions,
      ...SearchExtensions.withCounters(currentPubkey: currentPubkey, forKind: PostEntity.kind)
          .extensions,
      ...SearchExtensions.withAuthors(forKind: PostEntity.kind).extensions,
      ReferencesSearchExtension(contain: false),
      ExpirationSearchExtension(expiration: false),
      TagMarkerSearchExtension(
        tagName: RelatedReplaceableEvent.tagName,
        marker: RelatedEventMarker.reply.toShortString(),
        negative: true,
      ),
      TagMarkerSearchExtension(
        tagName: RelatedImmutableEvent.tagName,
        marker: RelatedEventMarker.reply.toShortString(),
        negative: true,
      ),
    ],
    if (includeArticles)
      ...SearchExtensions.withCounters(currentPubkey: currentPubkey, forKind: ArticleEntity.kind)
          .extensions,
    ...SearchExtensions.withAuthors(forKind: ArticleEntity.kind).extensions,
  ]).toString();

  return RequestFilter(
    kinds: [
      if (includePosts) ...[
        PostEntity.kind,
        ModifiablePostEntity.kind,
        RepostEntity.kind,
        GenericRepostEntity.modifiablePostRepostKind,
      ],
      if (includeArticles) ...[
        ArticleEntity.kind,
        GenericRepostEntity.articleRepostKind,
      ],
    ],
    tags: tags,
    search: search,
    authors: authors,
    limit: 20,
  );
}

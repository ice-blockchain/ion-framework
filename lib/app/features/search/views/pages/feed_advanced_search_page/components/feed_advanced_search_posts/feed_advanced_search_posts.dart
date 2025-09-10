// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/nothing_is_found/nothing_is_found.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/entities_list.dart';
import 'package:ion/app/features/components/entities_list/entities_list_skeleton.dart';
import 'package:ion/app/features/components/entities_list/entity_list_item.f.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/search/model/advanced_search_category.dart';
import 'package:ion/app/features/search/providers/feed_search_posts_data_source_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class FeedAdvancedSearchPosts extends HookConsumerWidget {
  const FeedAdvancedSearchPosts({
    required this.query,
    required this.category,
    super.key,
  });

  final String query;
  final AdvancedSearchCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final dataSource = ref.watch(
      feedSearchPostsDataSourceProvider(query: query, category: category),
    );
    final entitiesPagedData = ref.watch(entitiesPagedDataProvider(dataSource));
    final entities = entitiesPagedData?.data.items?.toList();

    return PullToRefreshBuilder(
      slivers: [
        if (entities == null)
          const EntitiesListSkeleton()
        else if (entities.isEmpty)
          NothingIsFound(title: context.i18n.search_nothing_found)
        else
          EntitiesList(
            items: entities
                .map((entity) => IonEntityListItem.event(eventReference: entity.toEventReference()))
                .toList(),
            onVideoTap: ({
              required String eventReference,
              required int initialMediaIndex,
              String? framedEventReference,
            }) =>
                FeedAdvancedSearchVideosRoute(
              eventReference: eventReference,
              initialMediaIndex: initialMediaIndex,
              framedEventReference: framedEventReference,
              query: query,
              category: category,
            ).push<void>(context),
          ),
      ],
      onRefresh: () async => ref.invalidate(entitiesPagedDataProvider(dataSource)),
      builder: (context, slivers) => LoadMoreBuilder(
        slivers: slivers,
        onLoadMore: ref.read(entitiesPagedDataProvider(dataSource).notifier).fetchEntities,
        hasMore: entitiesPagedData?.hasMore ?? false,
      ),
    );
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/search/model/advanced_search_category.dart';
import 'package:ion/app/features/search/providers/feed_search_posts_data_source_provider.r.dart';
import 'package:ion/app/features/video/views/pages/videos_vertical_scroll_page.dart';

class FeedAdvancedSearchVideosPage extends HookConsumerWidget {
  const FeedAdvancedSearchVideosPage({
    required this.query,
    required this.category,
    required this.eventReference,
    this.initialMediaIndex = 0,
    this.framedEventReference,
    super.key,
  });

  final String query;
  final AdvancedSearchCategory category;
  final EventReference eventReference;
  final EventReference? framedEventReference;
  final int initialMediaIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSource = ref.watch(
      feedSearchPostsDataSourceProvider(query: query, category: category),
    );
    final provider = ref.watch(entitiesPagedDataProvider(dataSource));
    final hasMore = provider?.hasMore ?? false;
    final entities = provider?.data.items ?? {};

    return VideosVerticalScrollPage(
      eventReference: eventReference,
      initialMediaIndex: initialMediaIndex,
      framedEventReference: framedEventReference,
      entities: entities,
      onLoadMore: hasMore
          ? () => ref.read(entitiesPagedDataProvider(dataSource).notifier).fetchEntities()
          : null,
    );
  }
}

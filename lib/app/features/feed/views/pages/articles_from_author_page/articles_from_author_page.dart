// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/features/components/entities_list/entities_list.dart';
import 'package:ion/app/features/components/entities_list/entities_list_skeleton.dart';
import 'package:ion/app/features/components/entities_list/entity_list_item.f.dart';
import 'package:ion/app/features/feed/providers/user_articles_data_source_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';

class ArticlesFromAuthorPage extends ConsumerWidget {
  const ArticlesFromAuthorPage({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorDisplayName = ref.watch(
      userPreviewDataProvider(pubkey).select(userPreviewDisplayNameSelector),
    );
    final dataSource = ref.watch(userArticlesDataSourceProvider(pubkey));
    final entitiesPagedData = ref.watch(entitiesPagedDataProvider(dataSource));
    final entities = entitiesPagedData?.data.items;

    return Scaffold(
      appBar: NavigationAppBar.screen(
        title: Text(authorDisplayName),
      ),
      body: LoadMoreBuilder(
        hasMore: entitiesPagedData?.hasMore ?? false,
        onLoadMore: ref.read(entitiesPagedDataProvider(dataSource).notifier).fetchEntities,
        slivers: [
          if (entities == null)
            const EntitiesListSkeleton()
          else
            EntitiesList(
              items: entities
                  .map(
                    (entity) => IonEntityListItem.event(eventReference: entity.toEventReference()),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/user/model/follow_type.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/follow_list_modal/components/follow_app_bar.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/follow_list_modal/components/follow_list_item.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/follow_list_modal/components/follow_list_loading.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/follow_list_modal/components/follow_search_bar.dart';
import 'package:ion/app/features/user/providers/relevant_followers_data_source_provider.r.dart';

class RelevantFollowersList extends ConsumerWidget {
  const RelevantFollowersList({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSource = ref.watch(relevantFollowersDataSourceProvider(pubkey, limit: 20));

    final entitiesPagedData =
        ref.watch(entitiesPagedDataProvider(dataSource, awaitMissingEvents: true));
    final entities = entitiesPagedData?.data.items?.toList();

    final followersCount = entities?.length ?? 0;

    final slivers = [
      FollowAppBar(title: FollowType.followers.getTitleWithCounter(context, followersCount)),
      const FollowSearchBar(),
      if (entities != null)
        SliverList.builder(
          itemCount: entities.length,
          itemBuilder: (context, index) {
            final entity = entities[index];
            final masterPubkey = switch (entity) {
              final EventsMetadataEntity eventsMetadata =>
                eventsMetadata.data.metadataEventReference?.masterPubkey ?? entity.masterPubkey,
              _ => entity.masterPubkey,
            };

            return ScreenSideOffset.small(
              child: FollowListItem(
                key: ValueKey(masterPubkey),
                pubkey: masterPubkey,
              ),
            );
          },
        )
      else
        const FollowListLoading(),
      SliverPadding(padding: EdgeInsetsDirectional.only(bottom: 32.0.s)),
    ];

    return ListCachedObjectsWrapper(
      child: LoadMoreBuilder(
        slivers: slivers,
        hasMore: entitiesPagedData?.hasMore ?? false,
        onLoadMore: ref.read(entitiesPagedDataProvider(dataSource).notifier).fetchEntities,
      ),
    );
  }
}

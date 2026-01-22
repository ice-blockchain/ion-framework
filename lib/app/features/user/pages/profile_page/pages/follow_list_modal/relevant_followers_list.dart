// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/user/model/follow_type.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/follow_list_modal/components/follow_app_bar.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/follow_list_modal/components/follow_list_item.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/follow_list_modal/components/follow_list_loading.dart';
import 'package:ion/app/features/user/providers/relevant_followers_data_source_provider.r.dart';
import 'package:ion/app/features/user/providers/relevant_followers_provider.r.dart';

class RelevantFollowersList extends ConsumerWidget {
  const RelevantFollowersList({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSource = ref.watch(relevantFollowersDataSourceProvider(pubkey, limit: 20));

    final result = ref.watch(relevantFollowersProvider(pubkey: pubkey));
    final masterPubkeys = result?.masterPubkeys;
    final hasMore = result?.hasMore ?? false;
    final isReady = result?.ready ?? false;
    final followersCount = masterPubkeys?.length ?? 0;

    final slivers = [
      FollowAppBar(title: FollowType.followers.getTitleWithCounter(context, followersCount)),
      if (masterPubkeys != null && isReady)
        SliverList.builder(
          itemCount: masterPubkeys.length,
          itemBuilder: (context, index) {
            return ScreenSideOffset.small(
              child: FollowListItem(
                key: ValueKey(masterPubkeys[index]),
                pubkey: masterPubkeys[index],
              ),
            );
          },
        )
      else
        const FollowListLoading(),
      SliverPadding(padding: EdgeInsetsDirectional.only(bottom: 32.0.s)),
    ];

    return LoadMoreBuilder(
      slivers: slivers,
      hasMore: hasMore,
      onLoadMore: ref
          .read(
            entitiesPagedDataProvider(
              dataSource,
              awaitMissingEvents: true,
            ).notifier,
          )
          .fetchEntities,
    );
  }
}

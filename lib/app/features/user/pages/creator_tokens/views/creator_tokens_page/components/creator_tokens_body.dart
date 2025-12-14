// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/global_search_tokens_provider.r.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/creator_tokens_list.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/tabs/creator_tokens_tab_content.dart';

class CreatorTokensBody extends ConsumerWidget {
  const CreatorTokensBody({
    required this.searchQuery,
    super.key,
  });

  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalSearch = ref.watch(globalSearchTokensNotifierProvider);
    final globalSearchNotifier = ref.watch(globalSearchTokensNotifierProvider.notifier);

    return IndexedStack(
      index: searchQuery.isNotEmpty ? 1 : 0,
      children: [
        TabBarView(
          children: CreatorTokensTabType.values.map(
            (tabType) {
              return CreatorTokensTabContent(
                tabType: tabType,
              );
            },
          ).toList(),
        ),
        LoadMoreBuilder(
          hasMore: globalSearch.activeHasMore,
          onLoadMore: globalSearchNotifier.loadMore,
          builder: (context, slivers) => PullToRefreshBuilder(
            onRefresh: globalSearchNotifier.refresh,
            builder: (_, slivers) => MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: CustomScrollView(
                slivers: slivers,
              ),
            ),
            slivers: slivers,
          ),
          slivers: [
            CreatorTokensList(
              items: globalSearch.activeItems,
              isInitialLoading: globalSearch.activeIsInitialLoading,
            ),
            SliverPadding(padding: EdgeInsetsDirectional.only(bottom: 12.0.s)),
          ],
        ),
      ],
    );
  }
}

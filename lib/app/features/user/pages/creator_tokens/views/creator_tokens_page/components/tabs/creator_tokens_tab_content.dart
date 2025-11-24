// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/features/communities/providers/category_tokens_provider.r.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/creator_tokens_list.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/tabs/creator_tokens_tab_header.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokensTabContent extends HookConsumerWidget {
  const CreatorTokensTabContent({
    required this.pubkey,
    required this.tabType,
    super.key,
  });

  final String pubkey;
  final CreatorTokensTabType tabType;

  TokenCategoryType? get _categoryType {
    return switch (tabType) {
      CreatorTokensTabType.trending => TokenCategoryType.trending,
      CreatorTokensTabType.top => TokenCategoryType.top,
      CreatorTokensTabType.latest => null,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryType = _categoryType;

    if (categoryType == null) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CreatorTokensTabHeader(tabType: tabType),
          ),
          const SliverToBoxAdapter(
            child: Center(
              child: Text('Latest category not yet implemented'),
            ),
          ),
        ],
      );
    }

    final state = ref.watch(categoryTokensNotifierProvider(categoryType));
    final hasMore = state.browsingHasMore;

    return LoadMoreBuilder(
      hasMore: hasMore,
      onLoadMore: () async {
        await ref.read(categoryTokensNotifierProvider(categoryType).notifier).loadMore();
      },
      slivers: [
        SliverToBoxAdapter(
          child: CreatorTokensTabHeader(tabType: tabType),
        ),
        CreatorTokensList(
          pubkey: pubkey,
          tabType: tabType,
        ),
      ],
    );
  }
}

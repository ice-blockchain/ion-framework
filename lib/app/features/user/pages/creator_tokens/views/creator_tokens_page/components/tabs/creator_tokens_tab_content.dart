// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/features/tokenized_communities/providers/category_tokens_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/latest_tokens_provider.r.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/creator_tokens_list.dart';

class CreatorTokensTabContent extends HookConsumerWidget {
  const CreatorTokensTabContent({
    required this.tabType,
    super.key,
  });

  final CreatorTokensTabType tabType;

  Future<void> _loadMore(WidgetRef ref) async {
    if (tabType.isLatest) {
      await ref.read(latestTokensNotifierProvider.notifier).loadMore();
    } else {
      await ref.read(categoryTokensNotifierProvider(tabType.categoryType!).notifier).loadMore();
    }
  }

  Future<void> _refresh(WidgetRef ref) async {
    if (tabType.isLatest) {
      await ref.read(latestTokensNotifierProvider.notifier).refresh();
    } else {
      await ref.read(categoryTokensNotifierProvider(tabType.categoryType!).notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    // Watch the appropriate provider based on tab type
    final state = tabType.isLatest
        ? ref.watch(latestTokensNotifierProvider)
        : ref.watch(categoryTokensNotifierProvider(tabType.categoryType!));

    return LoadMoreBuilder(
      hasMore: state.activeHasMore,
      onLoadMore: () => _loadMore(ref),
      builder: (context, slivers) => RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(slivers: slivers),
      ),
      slivers: [
        CreatorTokensList(
          items: state.activeItems,
          isInitialLoading: state.activeIsInitialLoading,
        ),
      ],
    );
  }
}

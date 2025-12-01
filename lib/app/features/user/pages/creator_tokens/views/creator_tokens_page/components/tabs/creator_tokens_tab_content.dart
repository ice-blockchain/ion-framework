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
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/tabs/creator_tokens_filter_bar.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/providers/creator_tokens_filter_provider.r.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/providers/creator_tokens_search_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokensTabContent extends HookConsumerWidget {
  const CreatorTokensTabContent({
    required this.tabType,
    super.key,
  });

  final CreatorTokensTabType tabType;

  void _search(WidgetRef ref, String query) {
    if (tabType.isLatest) {
      ref.read(latestTokensNotifierProvider.notifier).search(query);
    } else {
      ref.read(categoryTokensNotifierProvider(tabType.categoryType!).notifier).search(query);
    }
  }

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

  List<CommunityToken> _filterTokens(
    List<CommunityToken> tokens,
    CreatorTokensFilterType filterType,
  ) {
    if (filterType == CreatorTokensFilterType.allTokens) {
      return tokens;
    }

    return tokens.where((token) {
      final tokenType = CommunityTokenType.fromString(token.type);
      if (filterType == CreatorTokensFilterType.creatorTokens) {
        return tokenType.isCreatorToken;
      } else {
        // contentTokens filter
        return !tokenType.isCreatorToken;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final globalSearchQuery = ref.watch(creatorTokensSearchProvider);
    final isSearchActive = ref.watch(creatorTokensIsSearchActiveProvider);
    final debouncedQuery = useDebounced(globalSearchQuery, const Duration(milliseconds: 300)) ?? '';
    final lastSearchedQuery = useRef<String?>(null);

    // Watch filter state
    final selectedFilter = ref.watch(creatorTokensFilterProvider(tabType));

    // Watch the appropriate provider based on tab type
    final state = tabType.isLatest
        ? ref.watch(latestTokensNotifierProvider)
        : ref.watch(categoryTokensNotifierProvider(tabType.categoryType!));

    useEffect(
      () {
        if (debouncedQuery == lastSearchedQuery.value) return null;
        lastSearchedQuery.value = debouncedQuery;
        Future.microtask(() => _search(ref, debouncedQuery));
        return null;
      },
      [debouncedQuery, tabType],
    );

    useEffect(
      () {
        if (isSearchActive) {
          // Clear the last searched query to allow new search when user starts typing
          lastSearchedQuery.value = null;
        }
        return null;
      },
      [isSearchActive],
    );

    // Determine which items to show
    // When search is active but query is empty, show empty list
    final itemsToShow =
        isSearchActive && debouncedQuery.isEmpty ? <CommunityToken>[] : state.activeItems;

    // Apply filter to items
    final filteredItems = _filterTokens(itemsToShow, selectedFilter);

    return LoadMoreBuilder(
      hasMore: state.activeHasMore,
      onLoadMore: () => _loadMore(ref),
      builder: (context, slivers) => RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(slivers: slivers),
      ),
      slivers: [
        if (!isSearchActive)
          CreatorTokensFilterBar(
            selectedFilter: selectedFilter,
            onFilterChanged: (filter) {
              ref.read(creatorTokensFilterProvider(tabType).notifier).filter = filter;
            },
          ),
        CreatorTokensList(
          items: filteredItems,
          isInitialLoading: state.activeIsInitialLoading,
          isSearchActive: isSearchActive,
          searchQuery: debouncedQuery,
        ),
      ],
    );
  }
}

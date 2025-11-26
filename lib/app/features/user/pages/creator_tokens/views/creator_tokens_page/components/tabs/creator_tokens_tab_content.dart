// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/features/communities/providers/category_tokens_provider.r.dart';
import 'package:ion/app/features/communities/providers/latest_tokens_provider.r.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/creator_tokens_list.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/tabs/creator_tokens_search_bar.dart';

class CreatorTokensTabContent extends HookConsumerWidget {
  const CreatorTokensTabContent({
    required this.pubkey,
    required this.tabType,
    super.key,
  });

  final String pubkey;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final debouncedQuery = useDebounced(searchQuery.value, const Duration(milliseconds: 300)) ?? '';
    final lastSearchedQuery = useRef<String?>(null);

    // Watch the appropriate provider based on tab type
    final state = tabType.isLatest
        ? ref.watch(latestTokensNotifierProvider)
        : ref.watch(categoryTokensNotifierProvider(tabType.categoryType!));

    final searchInputIsLoading = state.isSearchMode && state.activeIsLoading;

    useEffect(
      () {
        if (debouncedQuery == lastSearchedQuery.value) return null;
        lastSearchedQuery.value = debouncedQuery;
        Future.microtask(() => _search(ref, debouncedQuery));
        return null;
      },
      [debouncedQuery, tabType],
    );

    return LoadMoreBuilder(
      hasMore: state.activeHasMore,
      onLoadMore: () => _loadMore(ref),
      builder: (context, slivers) => RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(slivers: slivers),
      ),
      slivers: [
        CreatorTokensSearchBar(
          controller: searchController,
          loading: searchInputIsLoading,
          onTextChanged: (value) => searchQuery.value = value,
          onCancelSearch: () {
            searchController.clear();
            searchQuery.value = '';
            _search(ref, '');
          },
        ),
        CreatorTokensList(
          items: state.activeItems,
          isInitialLoading: state.activeIsInitialLoading,
        ),
      ],
    );
  }
}

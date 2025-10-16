// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/components/nothing_is_found/nothing_is_found.dart';
import 'package:ion/app/components/screen_offset/screen_top_offset.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/search/providers/feed_search_history_provider.m.dart'
    show feedSearchHistoryProvider;
import 'package:ion/app/features/search/views/components/search_history/search_history.dart';
import 'package:ion/app/features/search/views/components/search_history_empty/search_history_empty.dart';
import 'package:ion/app/features/search/views/components/search_history_user_list_item/search_history_user_list_item.dart';
import 'package:ion/app/features/search/views/components/search_navigation/search_navigation.dart';
import 'package:ion/app/features/search/views/pages/feed_simple_search_page/feed_simple_search_list_item.dart';
import 'package:ion/app/features/user/providers/search_users_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class FeedSimpleSearchPage extends HookConsumerWidget {
  const FeedSimpleSearchPage({required this.query, super.key});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(feedSearchHistoryProvider);
    final debouncedQuery = useDebounced(query, const Duration(milliseconds: 300)) ?? '';
    final searchProvider = searchUsersProvider(query: debouncedQuery, includeCurrentUser: true);
    final searchResults = ref.watch(searchProvider).valueOrNull;
    final masterPubkeys = searchResults?.masterPubkeys ?? [];
    final hasMore = searchResults?.hasMore ?? true;
    final loading = (hasMore && masterPubkeys.isEmpty) || query != debouncedQuery;

    return Scaffold(
      body: ScreenTopOffset(
        child: ListCachedObjectsWrapper(
          child: Column(
            children: [
              SearchNavigation(
                query: query,
                loading: loading,
                onSubmitted: (String query) {
                  FeedAdvancedSearchRoute(query: query).go(context);
                  ref.read(feedSearchHistoryProvider.notifier).addQueryToTheHistory(query);
                },
                onTextChanged: (String text) {
                  FeedSimpleSearchRoute(query: text).replace(context);
                },
              ),
              if (query.isEmpty)
                history.pubKeys.isEmpty && history.queries.isEmpty
                    ? SearchHistoryEmpty(title: context.i18n.feed_search_empty)
                    : SearchHistory(
                        itemCount: history.pubKeys.length,
                        queries: history.queries,
                        onSelectQuery: (String query) {
                          FeedSimpleSearchRoute(query: query).replace(context);
                        },
                        onClearHistory: ref.read(feedSearchHistoryProvider.notifier).clear,
                        itemBuilder: (context, index) {
                          final pubkey = history.pubKeys[index];
                          return SearchHistoryUserListItem(
                            pubkey: pubkey,
                            onTap: () => ProfileRoute(pubkey: pubkey).push<void>(context),
                          );
                        },
                      )
              else
                Expanded(
                  child: PullToRefreshBuilder(
                    slivers: [
                      if (loading)
                        ListItemsLoadingState(
                          padding: EdgeInsets.symmetric(vertical: 20.0.s),
                          listItemsLoadingStateType: ListItemsLoadingStateType.scrollView,
                        )
                      else if (masterPubkeys.isEmpty)
                        NothingIsFound(title: context.i18n.search_nothing_found)
                      else
                        SliverPadding(
                          padding: EdgeInsets.symmetric(vertical: 12.0.s),
                          sliver: SliverList.builder(
                            itemCount: masterPubkeys.length,
                            itemBuilder: (context, index) => FeedSimpleSearchListItem(
                              masterPubkey: masterPubkeys[index],
                            ),
                          ),
                        ),
                    ],
                    onRefresh: () => ref.read(searchProvider.notifier).refresh(),
                    builder: (context, slivers) => LoadMoreBuilder(
                      slivers: slivers,
                      onLoadMore: () => ref.read(searchProvider.notifier).loadMore(),
                      hasMore: searchResults?.hasMore ?? false,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

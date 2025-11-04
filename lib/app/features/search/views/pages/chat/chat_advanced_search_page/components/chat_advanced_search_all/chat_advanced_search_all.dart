// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/providers/chat_search/chat_advanced_search_all_results_provider.r.dart';
import 'package:ion/app/features/search/providers/chat_search/chat_local_user_search_provider.r.dart';
import 'package:ion/app/features/search/providers/chat_search/chat_messages_search_provider.r.dart';
import 'package:ion/app/features/search/providers/chat_search/chat_privacy_cache_expiration_duration_provider.r.dart';
import 'package:ion/app/features/search/views/pages/chat/components/chat_no_results_found.dart';
import 'package:ion/app/features/search/views/pages/chat/components/chat_search_results_list_item.dart';
import 'package:ion/app/features/user/providers/search_users_provider.r.dart';

final double chatAdvancedSearchItemHeight = 66.5.s;

class ChatAdvancedSearchAll extends HookConsumerWidget {
  const ChatAdvancedSearchAll({required this.query, super.key});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final debouncedQuery = useDebounced(query, const Duration(milliseconds: 300)) ?? '';

    final expirationDuration = ref.watch(chatPrivacyCacheExpirationDurationProvider);

    final remoteUserSearch = ref.watch(
      searchUsersProvider(
        query: debouncedQuery,
        expirationDuration: expirationDuration,
      ),
    );

    final searchResultsAsync = ref.watch(chatAdvancedSearchAllResultsProvider(debouncedQuery));
    final searchResults = searchResultsAsync.valueOrNull ?? [];

    final hasMore = remoteUserSearch.valueOrNull?.hasMore ?? true;
    final isLoading = remoteUserSearch.isLoading ||
        searchResultsAsync.isLoading ||
        (hasMore && (remoteUserSearch.valueOrNull?.masterPubkeys ?? []).isEmpty);

    return PullToRefreshBuilder(
      slivers: [
        if (isLoading)
          const ListItemsLoadingState(
            listItemsLoadingStateType: ListItemsLoadingStateType.scrollView,
          )
        else if (searchResults.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: ChatSearchNoResults(),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(vertical: 12.0.s),
            sliver: SliverFixedExtentList(
              itemExtent: chatAdvancedSearchItemHeight,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Column(
                    children: [
                      const HorizontalSeparator(),
                      ChatSearchResultListItem(
                        showLastMessage: true,
                        item: searchResults[index],
                      ),
                      if (index == searchResults.length - 1) const HorizontalSeparator(),
                    ],
                  );
                },
                childCount: searchResults.length,
              ),
            ),
          ),
      ],
      onRefresh: () async {
        unawaited(
          ref
              .read(
                searchUsersProvider(
                  query: debouncedQuery,
                  expirationDuration: expirationDuration,
                ).notifier,
              )
              .refresh(),
        );
        ref
          ..invalidate(chatAdvancedSearchAllResultsProvider(debouncedQuery))
          ..invalidate(chatLocalUserSearchProvider(debouncedQuery))
          ..invalidate(chatMessagesSearchProvider(debouncedQuery));
      },
      builder: (context, slivers) => LoadMoreBuilder(
        slivers: slivers,
        onLoadMore: ref
            .read(
              searchUsersProvider(query: debouncedQuery, expirationDuration: expirationDuration)
                  .notifier,
            )
            .loadMore,
        hasMore: remoteUserSearch.valueOrNull?.hasMore ?? false,
      ),
    );
  }
}

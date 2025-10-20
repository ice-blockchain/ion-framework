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
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/search/model/chat_search_result_item.f.dart';
import 'package:ion/app/features/search/providers/chat_search/chat_local_user_search_provider.r.dart';
import 'package:ion/app/features/search/views/pages/chat/components/chat_no_results_found.dart';
import 'package:ion/app/features/search/views/pages/chat/components/chat_search_results_list_item.dart';
import 'package:ion/app/features/user/providers/search_users_provider.r.dart';

class ChatAdvancedSearchPeople extends HookConsumerWidget {
  const ChatAdvancedSearchPeople({required this.query, super.key});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final env = ref.read(envProvider.notifier);
    final expirationDuration = Duration(
      minutes: env.get<int>(EnvVariable.CHAT_PRIVACY_CACHE_MINUTES),
    );

    final remoteUserSearch =
        ref.watch(searchUsersProvider(query: query, expirationDuration: expirationDuration));
    final localUserSearch = ref.watch(chatLocalUserSearchProvider(query));

    final hasMore = remoteUserSearch.valueOrNull?.hasMore ?? true;

    final isLoading = (hasMore && (remoteUserSearch.valueOrNull?.masterPubkeys ?? []).isEmpty) ||
        localUserSearch.isLoading;

    final searchResults = [
      ...?localUserSearch.valueOrNull,
      if (remoteUserSearch.valueOrNull?.masterPubkeys != null)
        ...remoteUserSearch.value!.masterPubkeys!.map(
          (masterPubkey) => ChatSearchResultItem(masterPubkey: masterPubkey),
        ),
    ].distinctBy((item) => item.masterPubkey).toList();

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
          SliverFixedExtentList(
            itemExtent: 57.0.s, // Fixed height for search result items
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Column(
                  children: [
                    if (index == 0)
                      Padding(
                        padding: EdgeInsetsDirectional.only(top: 12.s),
                      ),
                    ChatSearchResultListItem(
                      showLastMessage: true,
                      item: searchResults[index],
                    ),
                    if (index == searchResults.length - 1)
                      Padding(
                        padding: EdgeInsetsDirectional.only(bottom: 12.s),
                        child: const HorizontalSeparator(),
                      )
                    else
                      const HorizontalSeparator(),
                  ],
                );
              },
              childCount: searchResults.length,
            ),
          ),
      ],
      onRefresh: () async {
        unawaited(
          ref
              .read(
                searchUsersProvider(query: query, expirationDuration: expirationDuration).notifier,
              )
              .refresh(),
        );
        ref.invalidate(chatLocalUserSearchProvider(query));
      },
      builder: (context, slivers) => LoadMoreBuilder(
        slivers: slivers,
        onLoadMore: ref
            .read(
              searchUsersProvider(query: query, expirationDuration: expirationDuration).notifier,
            )
            .loadMore,
        hasMore: remoteUserSearch.valueOrNull?.hasMore ?? false,
      ),
    );
  }
}

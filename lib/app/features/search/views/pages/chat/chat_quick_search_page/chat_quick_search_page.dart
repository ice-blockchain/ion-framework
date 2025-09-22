// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_top_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/search/model/chat_search_result_item.f.dart';
import 'package:ion/app/features/search/providers/chat_search/chat_local_user_search_provider.r.dart';
import 'package:ion/app/features/search/providers/chat_search/chat_search_history_provider.m.dart'
    show chatSearchHistoryProvider;
import 'package:ion/app/features/search/views/components/search_history/search_history.dart';
import 'package:ion/app/features/search/views/components/search_history_empty/search_history_empty.dart';
import 'package:ion/app/features/search/views/components/search_history_user_list_item/search_history_user_list_item.dart';
import 'package:ion/app/features/search/views/components/search_navigation/search_navigation.dart';
import 'package:ion/app/features/search/views/pages/chat/components/chat_no_results_found.dart';
import 'package:ion/app/features/search/views/pages/chat/components/chat_search_results.dart';
import 'package:ion/app/features/search/views/pages/chat/components/chat_search_results_skeleton.dart';
import 'package:ion/app/features/user/providers/search_users_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class ChatQuickSearchPage extends HookConsumerWidget {
  const ChatQuickSearchPage({required this.query, super.key});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(chatSearchHistoryProvider);
    final debouncedQuery = useDebounced(query, const Duration(milliseconds: 300)) ?? '';

    final hideCommunity =
        ref.watch(featureFlagsProvider.notifier).get(ChatFeatureFlag.hideCommunity);

    final env = ref.read(envProvider.notifier);
    final expirationDuration = Duration(
      minutes: env.get<int>(EnvVariable.CHAT_PRIVACY_CACHE_MINUTES),
    );

    final remoteUserSearch = ref.watch(
      searchUsersProvider(query: debouncedQuery, expirationDuration: expirationDuration),
    );
    final localUserSearch = ref.watch(chatLocalUserSearchProvider(debouncedQuery));

    final isLoading = remoteUserSearch.isLoading || localUserSearch.isLoading;

    final searchResults = [
      ...?localUserSearch.valueOrNull,
      if (remoteUserSearch.valueOrNull?.users != null)
        ...remoteUserSearch.value!.users!.map(
          (a) => ChatSearchResultItem(userMetadata: a),
        ),
    ].distinctBy((item) => item.userMetadata).toList();

    return Scaffold(
      body: ScreenTopOffset(
        child: Column(
          children: [
            SearchNavigation(
              query: query,
              loading: isLoading,
              onSubmitted: (String query) {
                ChatAdvancedSearchRoute(query: query).go(context);
                ref.read(chatSearchHistoryProvider.notifier).addQueryToTheHistory(query);
              },
              onTextChanged: (String text) => ChatQuickSearchRoute(query: text).replace(context),
            ),
            if (debouncedQuery.isEmpty)
              history.pubKeys.isEmpty && history.queries.isEmpty
                  ? SearchHistoryEmpty(
                      title: hideCommunity
                          ? context.i18n.chat_search_no_community_empty
                          : context.i18n.chat_search_empty,
                    )
                  : SearchHistory(
                      queries: history.queries,
                      itemCount: history.pubKeys.length,
                      onSelectQuery: (String text) =>
                          ChatQuickSearchRoute(query: text).replace(context),
                      onClearHistory: ref.read(chatSearchHistoryProvider.notifier).clear,
                      itemBuilder: (context, index) => SearchHistoryUserListItem(
                        pubkey: history.pubKeys[index],
                        onTap: () => ConversationRoute(receiverMasterPubkey: history.pubKeys[index])
                            .push<void>(context),
                      ),
                    )
            else if (isLoading)
              const ChatSearchResultsSkeleton()
            else if (searchResults.isEmpty)
              const Expanded(child: ChatSearchNoResults())
            else
              Expanded(
                child: ChatSearchResults(
                  searchResults: searchResults,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

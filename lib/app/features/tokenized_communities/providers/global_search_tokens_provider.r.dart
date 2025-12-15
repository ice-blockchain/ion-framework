// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/providers/global_search_tokens_state.f.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_search_tokens_provider.r.g.dart';

@riverpod
class GlobalSearchTokensNotifier extends _$GlobalSearchTokensNotifier {
  static const int _limit = 10;

  @override
  GlobalSearchTokensState build() => const GlobalSearchTokensState();

  Future<void> search({
    required String query,
    int? includeTopPlatformHolders,
  }) async {
    if (query.isEmpty) {
      state = const GlobalSearchTokensState();
      return;
    }

    state = state.copyWith(
      searchQuery: query,
      searchItems: const <CommunityToken>[],
      searchOffset: 0,
      searchHasMore: true,
      searchIsLoading: true,
      searchIsInitialLoading: true,
    );

    try {
      final client = await ref.read(ionTokenAnalyticsClientProvider.future);
      final page = await client.communityTokens.getGlobalSearchTokens(
        externalAddresses: const [],
        keyword: query,
        includeTopPlatformHolders: includeTopPlatformHolders,
        limit: _limit,
      );

      state = state.copyWith(
        searchItems: page.items,
        searchOffset: page.nextOffset,
        searchHasMore: page.hasMore,
        searchIsLoading: false,
        searchIsInitialLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        searchIsLoading: false,
        searchIsInitialLoading: false,
      );
      rethrow;
    }
  }

  Future<void> loadMore({
    int? includeTopPlatformHolders,
  }) async {
    if (!state.searchHasMore || state.searchIsLoading || (state.searchQuery?.isEmpty ?? true)) {
      return;
    }

    state = state.copyWith(searchIsLoading: true);

    try {
      final client = await ref.read(ionTokenAnalyticsClientProvider.future);
      final page = await client.communityTokens.getGlobalSearchTokens(
        externalAddresses: const [],
        keyword: state.searchQuery,
        includeTopPlatformHolders: includeTopPlatformHolders,
        limit: _limit,
        offset: state.searchOffset,
      );

      state = state.copyWith(
        searchItems: [...state.searchItems, ...page.items],
        searchOffset: page.nextOffset,
        searchHasMore: page.hasMore,
        searchIsLoading: false,
      );
    } catch (_) {
      state = state.copyWith(searchIsLoading: false);
      rethrow;
    }
  }

  Future<void> refresh({
    int? includeTopPlatformHolders,
  }) async {
    final currentQuery = state.searchQuery;
    if (currentQuery == null || currentQuery.isEmpty) {
      state = const GlobalSearchTokensState();
      return;
    }
    await search(
      query: currentQuery,
      includeTopPlatformHolders: includeTopPlatformHolders,
    );
  }
}

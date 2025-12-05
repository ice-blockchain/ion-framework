// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/tokenized_communities/providers/latest_tokens_state.f.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'latest_tokens_provider.r.g.dart';

@riverpod
class LatestTokensNotifier extends _$LatestTokensNotifier {
  static const int _limit = 10;

  NetworkSubscription<dynamic>? _realtimeSubscription;

  @override
  LatestTokensState build() {
    ref.onDispose(() async {
      await _realtimeSubscription?.close();
      _realtimeSubscription = null;
    });

    Future.microtask(_initialize);

    return const LatestTokensState();
  }

  Future<void> _initialize() async {
    if (_realtimeSubscription == null) {
      await _subscribeToRealtimeUpdates();
    }
    await _loadInitial();
  }

  Future<void> _subscribeToRealtimeUpdates() async {
    final client = await ref.read(ionTokenAnalyticsClientProvider.future);
    _realtimeSubscription = await client.communityTokens.subscribeToLatestTokens();
    _realtimeSubscription!.stream.listen(_handleRealtimeEvent);
  }

  Future<void> _loadInitial() async {
    if (state.browsingIsLoading || state.browsingIsInitialLoading) return;

    state = state.copyWith(
      browsingIsInitialLoading: true,
      browsingIsLoading: true,
    );

    try {
      final client = await ref.read(ionTokenAnalyticsClientProvider.future);
      final page = await client.communityTokens.getLatestTokens(limit: _limit);

      state = state.copyWith(
        browsingItems: _appendUnique(
          base: state.browsingItems,
          incoming: page.items,
        ),
        browsingOffset: state.browsingOffset + page.items.length,
        browsingHasMore: page.hasMore,
        browsingIsLoading: false,
        browsingIsInitialLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        browsingIsLoading: false,
        browsingIsInitialLoading: false,
      );
      rethrow;
    }
  }

  Future<void> loadMore() async {
    if (state.searchQuery != null) {
      await _loadMoreSearch();
    } else {
      await _loadMoreBrowsing();
    }
  }

  Future<void> _loadMoreBrowsing() async {
    if (!state.browsingHasMore || state.browsingIsLoading) return;

    state = state.copyWith(browsingIsLoading: true);

    try {
      final client = await ref.read(ionTokenAnalyticsClientProvider.future);
      final page = await client.communityTokens.getLatestTokens(
        limit: _limit,
        offset: state.browsingOffset,
      );

      state = state.copyWith(
        browsingItems: _appendUnique(
          base: state.browsingItems,
          incoming: page.items,
        ),
        browsingOffset: state.browsingOffset + page.items.length,
        browsingHasMore: page.hasMore,
        browsingIsLoading: false,
      );
    } catch (_) {
      state = state.copyWith(browsingIsLoading: false);
      rethrow;
    }
  }

  Future<void> _loadMoreSearch() async {
    if (!state.searchHasMore || state.searchIsLoading) return;

    state = state.copyWith(searchIsLoading: true);

    try {
      final client = await ref.read(ionTokenAnalyticsClientProvider.future);
      final page = await client.communityTokens.getLatestTokens(
        keyword: state.searchQuery,
        limit: _limit,
        offset: state.searchOffset,
      );

      state = state.copyWith(
        searchItems: _appendUnique(
          base: state.searchItems,
          incoming: page.items,
        ),
        searchOffset: state.searchOffset + page.items.length,
        searchHasMore: page.hasMore,
        searchIsLoading: false,
      );
    } catch (_) {
      state = state.copyWith(searchIsLoading: false);
      rethrow;
    }
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchQuery: null);
      return;
    }

    if (state.searchQuery == query) return;

    state = state.copyWith(
      searchQuery: query,
      searchItems: <CommunityToken>[],
      searchOffset: 0,
      searchHasMore: true,
      searchIsLoading: true,
      searchIsInitialLoading: true,
    );

    try {
      final client = await ref.read(ionTokenAnalyticsClientProvider.future);
      final page = await client.communityTokens.getLatestTokens(
        keyword: query,
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

  Future<void> refresh() async {
    await _realtimeSubscription?.close();
    _realtimeSubscription = null;
    state = const LatestTokensState();
    await _initialize();
  }

  void _handleRealtimeEvent(dynamic event) {
    if (event is CommunityToken) {
      _prependToken(event);
      return;
    }

    if (event is CommunityTokenPatch) {
      _applyPatch(event);
    }
  }

  List<CommunityToken> _appendUnique({
    required List<CommunityToken> base,
    required List<CommunityToken> incoming,
  }) {
    final updated = List<CommunityToken>.from(base);

    for (final token in incoming) {
      final exists = updated.any(
        (existing) => existing.addresses.ionConnect == token.addresses.ionConnect,
      );

      if (!exists) {
        updated.add(token);
      }
    }

    return updated;
  }

  void _prependToken(CommunityToken token) {
    final existingIndex = state.browsingItems.indexWhere(
      (item) => item.addresses.ionConnect == token.addresses.ionConnect,
    );
    final updatedItems = List<CommunityToken>.from(state.browsingItems);

    if (existingIndex != -1) {
      updatedItems[existingIndex] = token;
      state = state.copyWith(browsingItems: updatedItems);
      return;
    }

    updatedItems.insert(0, token);

    state = state.copyWith(
      browsingItems: updatedItems,
      browsingOffset: state.browsingOffset + 1,
    );
  }

  void _applyPatch(CommunityTokenPatch patch) {
    final ionConnect = patch.addresses?.ionConnect;
    if (ionConnect == null) return;

    final existingIndex =
        state.browsingItems.indexWhere((token) => token.addresses.ionConnect == ionConnect);

    if (existingIndex != -1) {
      final existing = state.browsingItems[existingIndex];
      final updated = existing.merge(patch);
      final updatedItems = List<CommunityToken>.from(state.browsingItems);
      updatedItems[existingIndex] = updated;
      state = state.copyWith(browsingItems: updatedItems);
    } else {
      try {
        final newToken = CommunityToken.fromJson(patch.toJson());
        _prependToken(newToken);
      } catch (_) {
        // Ignore patches that can't form a full entity.
      }
    }
  }
}

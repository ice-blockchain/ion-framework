// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/communities/providers/category_tokens_state.f.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_tokens_provider.r.g.dart';

@riverpod
class CategoryTokensNotifier extends _$CategoryTokensNotifier {
  static const int _limit = 10;
  NetworkSubscription<List<CommunityTokenBase>>? _realtimeSubscription;
  late final TokenCategoryType _type;

  @override
  CategoryTokensState build(TokenCategoryType type) {
    _type = type;

    ref.onDispose(() async {
      await _realtimeSubscription?.close();
      _realtimeSubscription = null;
    });

    Future.microtask(_initialize);

    return const CategoryTokensState();
  }

  Future<void> _initialize() async {
    if (state.sessionId != null) return;

    final client = await ref.read(ionTokenAnalyticsClientProvider.future);
    final session = await client.communityTokens.createViewingSession(_type);

    state = state.copyWith(sessionId: session.id);

    await _subscribeToRealtimeUpdates(session.id, _type);
    await _loadInitial();
  }

  Future<void> _loadInitial() async {
    if (state.browsingIsLoading || state.browsingIsInitialLoading) return;

    state = state.copyWith(browsingIsInitialLoading: true, browsingIsLoading: true);

    try {
      final client = await ref.read(ionTokenAnalyticsClientProvider.future);
      final page = await client.communityTokens.getCategoryTokens(
        sessionId: state.sessionId!,
        type: _type,
        limit: _limit,
      );

      state = state.copyWith(
        browsingItems: page.items,
        browsingOffset: page.nextOffset,
        browsingHasMore: page.hasMore,
        browsingIsLoading: false,
        browsingIsInitialLoading: false,
      );
    } catch (e) {
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
      final page = await client.communityTokens.getCategoryTokens(
        sessionId: state.sessionId!,
        type: _type,
        limit: _limit,
        offset: state.browsingOffset,
      );

      state = state.copyWith(
        browsingItems: [...state.browsingItems, ...page.items],
        browsingOffset: page.nextOffset,
        browsingHasMore: page.hasMore,
        browsingIsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(browsingIsLoading: false);
      rethrow;
    }
  }

  Future<void> _loadMoreSearch() async {
    if (!state.searchHasMore || state.searchIsLoading) return;

    state = state.copyWith(searchIsLoading: true);

    try {
      final client = await ref.read(ionTokenAnalyticsClientProvider.future);
      final page = await client.communityTokens.getCategoryTokens(
        sessionId: state.sessionId!,
        type: _type,
        keyword: state.searchQuery,
        limit: _limit,
        offset: state.searchOffset,
      );

      state = state.copyWith(
        searchItems: [...state.searchItems, ...page.items],
        searchOffset: page.nextOffset,
        searchHasMore: page.hasMore,
        searchIsLoading: false,
      );
    } catch (e) {
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
      final page = await client.communityTokens.getCategoryTokens(
        sessionId: state.sessionId!,
        type: _type,
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
    } catch (e) {
      state = state.copyWith(
        searchIsLoading: false,
        searchIsInitialLoading: false,
      );
      rethrow;
    }
  }

  Future<void> _subscribeToRealtimeUpdates(String sessionId, TokenCategoryType type) async {
    final client = await ref.read(ionTokenAnalyticsClientProvider.future);
    await _realtimeSubscription?.close();
    _realtimeSubscription = await client.communityTokens.subscribeToCategoryTokens(
      sessionId: sessionId,
      type: type,
    );

    _realtimeSubscription!.stream.listen(_handleRealtimeEvent);
  }

  void _handleRealtimeEvent(List<CommunityTokenBase> events) {
    for (final event in events) {
      if (event is CommunityToken) {
        _prependToken(event);
      }

      if (event is CommunityTokenPatch) {
        _applyPatch(event);
      }
    }
  }

  void _prependToken(CommunityToken token) {
    final existingIndex = state.browsingItems.indexWhere(
      (item) => item.addresses.ionConnect == token.addresses.ionConnect,
    );

    if (existingIndex != -1) {
      final updatedItems = List<CommunityToken>.from(state.browsingItems);
      updatedItems[existingIndex] = token;
      state = state.copyWith(browsingItems: updatedItems);
      return;
    }

    state = state.copyWith(
      browsingItems: [token, ...state.browsingItems],
    );
  }

  void _applyPatch(CommunityTokenPatch patch) {
    final ionConnect = patch.addresses?.ionConnect;
    if (ionConnect == null) return;

    final existingIndex = state.browsingItems.indexWhere(
      (token) => token.addresses.ionConnect == ionConnect,
    );

    if (existingIndex != -1) {
      final existing = state.browsingItems[existingIndex];
      final updated = existing.merge(patch);
      final updatedItems = List<CommunityToken>.from(state.browsingItems);
      updatedItems[existingIndex] = updated;
      state = state.copyWith(browsingItems: updatedItems);
    } else {
      try {
        final newToken = CommunityToken.fromJson(patch.toJson());
        state = state.copyWith(
          browsingItems: [newToken, ...state.browsingItems],
        );
      } catch (_) {
        // Ignore patches that can't form a full entity.
      }
    }
  }

  Future<void> refresh() async {
    await _realtimeSubscription?.close();
    _realtimeSubscription = null;
    state = const CategoryTokensState();
    await _initialize();
  }
}

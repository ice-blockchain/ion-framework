// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/tokenized_communities/providers/tokens_state.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

part 'global_search_tokens_state.f.freezed.dart';

@freezed
class GlobalSearchTokensState with _$GlobalSearchTokensState implements TokensState {
  const factory GlobalSearchTokensState({
    @Default(<CommunityToken>[]) List<CommunityToken> searchItems,
    @Default(0) int searchOffset,
    @Default(true) bool searchHasMore,
    @Default(false) bool searchIsLoading,
    @Default(false) bool searchIsInitialLoading,
    String? searchQuery,
  }) = _GlobalSearchTokensState;

  const GlobalSearchTokensState._();

  @override
  bool get isSearchMode => searchQuery?.isNotEmpty ?? false;

  @override
  List<CommunityToken> get activeItems => searchItems;

  @override
  bool get activeHasMore => searchHasMore;

  @override
  bool get activeIsLoading => searchIsLoading;

  @override
  bool get activeIsInitialLoading => searchIsInitialLoading;
}

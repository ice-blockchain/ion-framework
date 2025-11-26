// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

part 'latest_tokens_state.f.freezed.dart';

@freezed
class LatestTokensState with _$LatestTokensState {
  const factory LatestTokensState({
    @Default([]) List<CommunityToken> browsingItems,
    @Default(0) int browsingOffset,
    @Default(true) bool browsingHasMore,
    @Default(false) bool browsingIsLoading,
    @Default(false) bool browsingIsInitialLoading,
    @Default([]) List<CommunityToken> searchItems,
    @Default(0) int searchOffset,
    @Default(true) bool searchHasMore,
    @Default(false) bool searchIsLoading,
    @Default(false) bool searchIsInitialLoading,
    String? searchQuery,
  }) = _LatestTokensState;
}

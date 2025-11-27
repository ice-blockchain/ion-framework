// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';

// Common interface for token list states (CategoryTokensState, LatestTokensState).
// Provides unified access to browsing/search state regardless of the underlying type.
abstract class TokensState {
  bool get isSearchMode;
  List<CommunityToken> get activeItems;
  bool get activeHasMore;
  bool get activeIsLoading;
  bool get activeIsInitialLoading;
}

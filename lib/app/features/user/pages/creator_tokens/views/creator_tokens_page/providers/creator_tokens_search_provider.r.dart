// SPDX-License-Identifier: ice License 1.0

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'creator_tokens_search_provider.r.g.dart';

@riverpod
class CreatorTokensSearch extends _$CreatorTokensSearch {
  @override
  String build() {
    return '';
  }

  set searchQuery(String query) {
    state = query;
  }

  void clearSearch() {
    state = '';
  }
}

@riverpod
class CreatorTokensIsSearchActive extends _$CreatorTokensIsSearchActive {
  @override
  bool build() {
    return false;
  }

  set isSearching(bool isSearching) {
    state = isSearching;
  }
}

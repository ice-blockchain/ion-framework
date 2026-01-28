// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/enums/tokenized_community_token_type.f.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/token_type_filter.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/filtered_assets_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/providers/wallet_coins_filter_provider.r.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'filtered_coins_provider.r.g.dart';

@riverpod
List<CoinsGroup>? filteredCoins(Ref ref) {
  final groups = ref.watch(filteredCoinsNotifierProvider.select((state) => state.valueOrNull));
  final selectedFilter = ref.watch(walletCoinsFilterNotifierProvider);

  if (groups == null) {
    return null;
  }

  return groups.where((group) {
    if (selectedFilter == TokenTypeFilter.all) {
      return true;
    }
    return group.coins.any((coinInWallet) {
      final coin = coinInWallet.coin;
      final tokenType = coin.tokenizedCommunityTokenType;

      if (tokenType == null) {
        // Regular coin - matches "all" and "general" filters
        return selectedFilter == TokenTypeFilter.all || selectedFilter == TokenTypeFilter.general;
      }

      return switch (selectedFilter) {
        TokenTypeFilter.all => true,
        TokenTypeFilter.general => false,
        TokenTypeFilter.creator => tokenType == TokenizedCommunityTokenType.tokenTypeProfile,
        TokenTypeFilter.content => tokenType == TokenizedCommunityTokenType.tokenTypePost ||
            tokenType == TokenizedCommunityTokenType.tokenTypeArticle ||
            tokenType == TokenizedCommunityTokenType.tokenTypeVideo,
        TokenTypeFilter.x => tokenType == TokenizedCommunityTokenType.tokenTypeXcom,
      };
    });
  }).toList();
}

@riverpod
double? filteredCoinsBalance(Ref ref) {
  final filteredGroups = ref.watch(filteredCoinsProvider);

  if (filteredGroups == null) {
    return null;
  }

  return filteredGroups.fold<double>(
    0,
    (sum, group) => sum + group.totalBalanceUSD,
  );
}

// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/tokenized_communities/enums/tokenized_community_token_type.f.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/token_type_filter.dart';
import 'package:ion/app/features/wallets/data/database/dao/transactions_visibility_status_dao.m.dart';
import 'package:ion/app/features/wallets/providers/filtered_assets_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/coins_list/coin_item.dart';
import 'package:ion/app/features/wallets/views/pages/manage_coins/providers/manage_coins_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/coins/coins_tab_footer.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/empty_state/empty_state.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/providers/wallet_coins_filter_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/providers/wallet_page_loader_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/tab_type.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class CoinsTab extends ConsumerWidget {
  const CoinsTab({
    required this.tabType,
    super.key,
  });

  final WalletTabType tabType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPageLoading = ref.watch(walletPageLoaderNotifierProvider);

    if (isPageLoading) {
      return _CoinsTabBody(
        itemCount: 4,
        itemBuilder: (_, __) => ScreenSideOffset.small(child: const CoinsGroupItemPlaceholder()),
      );
    }

    final groups = ref.watch(filteredCoinsNotifierProvider.select((state) => state.valueOrNull));
    final selectedFilter = ref.watch(walletCoinsFilterNotifierProvider);

    final filteredGroups = groups?.where((group) {
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

    if (filteredGroups == null || filteredGroups.isEmpty) {
      return EmptyState(
        tabType: tabType,
        onBottomActionTap: () {
          ManageCoinsRoute().go(context);
        },
      );
    }

    return _CoinsTabBody(
      itemCount: filteredGroups.length,
      itemBuilder: (context, index) {
        final group = filteredGroups[index];

        final isUpdating = ref.watch(
          manageCoinsNotifierProvider.select(
            (state) => state.valueOrNull?[group.symbolGroup]?.isUpdating ?? false,
          ),
        );

        return ScreenSideOffset.small(
          child: isUpdating
              ? const CoinsGroupItemPlaceholder()
              : CoinsGroupItem(
                  showNewTransactionsIndicator: true,
                  coinsGroup: group,
                  onTap: () {
                    ref.read(transactionsVisibilityStatusDaoProvider).addOrUpdateVisibilityStatus(
                          coinIds: group.coins.map((e) => e.coin.id).toList(),
                          status: TransactionVisibilityStatus.seen,
                        );
                    return CoinsDetailsRoute(symbolGroup: group.symbolGroup).go(context);
                  },
                ),
        );
      },
    );
  }
}

class _CoinsTabBody extends StatelessWidget {
  const _CoinsTabBody({
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverList.separated(
          itemCount: itemCount,
          separatorBuilder: (context, index) => SizedBox(height: 12.0.s),
          itemBuilder: itemBuilder,
        ),
        const CoinsTabFooter(),
      ],
    );
  }
}

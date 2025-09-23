// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/wallets/data/database/dao/transactions_visibility_status_dao.m.dart';
import 'package:ion/app/features/wallets/providers/filtered_assets_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/coins_list/coin_item.dart';
import 'package:ion/app/features/wallets/views/pages/manage_coins/providers/manage_coins_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/coins/coins_tab_footer.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/empty_state/empty_state.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/providers/wallet_page_loader_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/tab_type.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class CoinsTab extends ConsumerWidget {
  const CoinsTab({
    super.key,
  });

  static const WalletTabType tabType = WalletTabType.coins;

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

    if (groups == null || groups.isEmpty) {
      return EmptyState(
        tabType: tabType,
        onBottomActionTap: () {
          ManageCoinsRoute().go(context);
        },
      );
    }

    return _CoinsTabBody(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];

        final isUpdating = ref.watch(
          manageCoinsNotifierProvider.select(
            (state) => state.valueOrNull?[group.symbolGroup]?.isUpdating ?? false,
          ),
        );

        return ScreenSideOffset.small(
          child: isUpdating
              ? CoinsGroupItemPlaceholder(key: ValueKey('placeholder-${group.symbolGroup}'))
              : CoinsGroupItem(
                  key: ValueKey('item-${group.symbolGroup}'),
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

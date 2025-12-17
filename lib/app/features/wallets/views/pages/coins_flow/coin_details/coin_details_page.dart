// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/domain/transactions/sync_transactions_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/info_type.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/info_block_button.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/balance/balance.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/empty_state/empty_state.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/transaction_list_item/transaction_list_header.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/transaction_list_item/transaction_list_item.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/transaction_list_item/transaction_section_header.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/coin_transaction_history_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/network_selector_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/utils/date.dart';

class CoinDetailsPage extends HookConsumerWidget {
  const CoinDetailsPage({required this.symbolGroup, super.key});

  final String symbolGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletView = ref.watch(currentWalletViewDataProvider).requireValue;
    final coinsGroup = walletView.coinGroups.firstWhere((e) => e.symbolGroup == symbolGroup);
    final networkSelectorData = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup),
    );
    final history = ref
        .watch(
          coinTransactionHistoryNotifierProvider(symbolGroup: symbolGroup),
        )
        .valueOrNull;
    final historyNotifier = ref.watch(
      coinTransactionHistoryNotifierProvider(symbolGroup: symbolGroup).notifier,
    );

    final isTransactionsLoading = history == null || history.isLoading;

    final coinTransactionsMap = useMemoized(
      () {
        final sorted = (history?.transactions ?? <CoinTransactionData>[]).sorted(
          (t1, t2) => t2.timestamp.compareTo(t1.timestamp),
        );
        final grouped = groupBy(
          sorted,
          (CoinTransactionData tx) => toPastDateDisplayValue(tx.timestamp, context),
        );
        return grouped;
      },
      [history, context],
    );

    final containsTier2Network = useMemoized(
      () => coinsGroup.coins.any((coin) => coin.coin.network.tier != 1),
      [coinsGroup],
    );

    return Scaffold(
      appBar: NavigationAppBar.screen(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CoinIconWidget(imageUrl: coinsGroup.iconUrl, type: WalletItemIconType.medium()),
            SizedBox(width: 6.0.s),
            Text(coinsGroup.name),
            if (containsTier2Network) ...[
              SizedBox(width: 2.0.s),
              const InfoBlockButton(
                infoType: InfoType.transactionsInTier2Network,
              ),
            ],
          ],
        ),
      ),
      body: LoadMoreBuilder(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SectionSeparator(),
                Balance(
                  coinsGroup: coinsGroup,
                  currentNetwork: networkSelectorData?.selected.map(
                    network: (item) => item.network,
                    all: (_) => null,
                  ),
                ),
                const SectionSeparator(),
              ],
            ),
          ),
          if (networkSelectorData != null)
            SliverToBoxAdapter(
              child: TransactionListHeader(
                items: networkSelectorData.items,
                selected: networkSelectorData.selected,
                onNetworkTypeSelect: (selected) {
                  ref
                      .read(networkSelectorNotifierProvider(symbolGroup: symbolGroup).notifier)
                      .selected = selected;
                },
              ),
            ),
          if (coinTransactionsMap.isEmpty && !isTransactionsLoading) const EmptyState(),
          if (isTransactionsLoading)
            ListItemsLoadingState(
              itemsCount: 10,
              separatorHeight: 12.0.s,
              listItemsLoadingStateType: ListItemsLoadingStateType.scrollView,
            ),
          if (coinTransactionsMap.isNotEmpty && !isTransactionsLoading)
            for (final MapEntry<String, List<CoinTransactionData>>(
                  key: String date,
                  value: List<CoinTransactionData> transactions
                ) in coinTransactionsMap.entries) ...[
              SliverToBoxAdapter(
                child: TransactionSectionHeader(
                  date: date,
                ),
              ),
              SliverList.separated(
                itemCount: transactions.length,
                separatorBuilder: (BuildContext context, int index) => SizedBox(height: 12.0.s),
                itemBuilder: (BuildContext context, int index) {
                  return ScreenSideOffset.small(
                    child: TransactionListItem(
                      transactionData: transactions[index],
                      coinData: coinsGroup.coins.first.coin,
                      onTap: () {
                        final transaction = transactions[index].origin;

                        CoinTransactionDetailsRoute(
                          txHash: transaction.txHash,
                          typeValue: transaction.type.value,
                          walletViewId: transaction.walletViewId,
                        ).push<void>(context);
                      },
                    ),
                  );
                },
              ),
            ],
          SliverToBoxAdapter(
            child: ScreenBottomOffset(),
          ),
        ],
        hasMore: history?.hasMore ?? false,
        onLoadMore: historyNotifier.loadMore,
        builder: (context, slivers) => PullToRefreshBuilder(
          onRefresh: () async {
            ref
              ..invalidate(walletViewsDataNotifierProvider)
              ..invalidate(coinTransactionHistoryNotifierProvider(symbolGroup: symbolGroup));

            // Sync transactions for this specific coin across all networks
            final syncService = await ref.read(syncTransactionsServiceProvider.future);
            await syncService.syncCoinTransactions(symbolGroup);
          },
          slivers: slivers,
        ),
      ),
    );
  }
}

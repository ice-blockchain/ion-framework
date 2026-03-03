// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/wallets/model/coin_transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_selector_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/empty_state/empty_state.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/transaction_list_item/transaction_list_item.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/transaction_list_item/transaction_section_header.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/coin_transaction_history_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/network_selector_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/date.dart';

class CoinTransactionHistory extends HookConsumerWidget {
  const CoinTransactionHistory({
    required this.symbolGroup,
    required this.coinsGroup,
    required this.selectedNetwork,
    super.key,
  });

  final String symbolGroup;
  final CoinsGroup coinsGroup;
  final SelectedNetworkItem? selectedNetwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(
      coinTransactionHistoryNotifierProvider(symbolGroup: symbolGroup),
    );
    final history = historyAsync.valueOrNull;

    final providerNetwork = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup)
          .select((s) => s.valueOrNull?.selected),
    );

    final isNetworkChangePending = selectedNetwork != providerNetwork;
    final isLoading = history == null || isNetworkChangePending;

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

    if (coinTransactionsMap.isEmpty && !isLoading) {
      return const EmptyState();
    }

    if (isLoading) {
      return ListItemsLoadingState(
        itemsCount: 10,
        separatorHeight: 12.0.s,
        listItemsLoadingStateType: ListItemsLoadingStateType.scrollView,
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        for (final MapEntry<String, List<CoinTransactionData>>(
              key: String date,
              value: List<CoinTransactionData> transactions,
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
                      transactionIndex: transaction.index,
                    ).push<void>(context);
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

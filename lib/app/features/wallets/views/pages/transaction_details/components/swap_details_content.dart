// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/skeleton/container_skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/transaction_details.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/features/wallets/providers/swap_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/swap_details_card.dart';
import 'package:ion/app/features/wallets/views/pages/transaction_details/components/actions_section.dart';
import 'package:ion/app/features/wallets/views/pages/transaction_details/transaction_details.dart';
import 'package:ion/app/services/share/share.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';

class SwapDetailsContent extends ConsumerWidget {
  const SwapDetailsContent({
    required this.selectedTransaction,
    required this.onViewOnExplorer,
    super.key,
  });

  final TransactionDetails selectedTransaction;
  final VoidCallback onViewOnExplorer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapAsync = ref.watch(swapDetailsProvider(selectedTransaction.txHash));

    final assetAbbreviation =
        selectedTransaction.assetData.mapOrNull(coin: (coin) => coin.coinsGroup)?.abbreviation;
    final disableTransactionDetailsButtons = abbreviationsToExclude.contains(assetAbbreviation) &&
        (selectedTransaction.status != TransactionStatus.confirmed &&
            selectedTransaction.status != TransactionStatus.failed);

    final loader = [
      const SliverToBoxAdapter(
        child: _SwapDetailsCardSkeleton(),
      ),
      SliverToBoxAdapter(
        child: SizedBox(height: 20.s),
      ),
    ];

    return CustomScrollView(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        ...swapAsync.when(
          skipLoadingOnReload: true,
          data: (swap) {
            if (swap == null) return loader;

            final fromTransaction = swap.fromTransaction;
            final toTransaction = swap.toTransaction;

            if (fromTransaction == null || toTransaction == null) return loader;

            final isSellFirst = selectedTransaction.type == TransactionType.send;
            final sellTransaction = isSellFirst ? fromTransaction : toTransaction;
            final buyTransaction = isSellFirst ? toTransaction : fromTransaction;

            final sellCoinData = sellTransaction.assetData.mapOrNull(coin: (coin) => coin)!;
            final buyCoinData = buyTransaction.assetData.mapOrNull(coin: (coin) => coin)!;

            final sellCoins = sellCoinData.coinsGroup;
            final buyCoins = buyCoinData.coinsGroup;
            final sellNetwork = sellTransaction.network;
            final buyNetwork = buyTransaction.network;

            final sellAmount = sellCoinData.amount.formatMax6 ?? '0';
            final buyAmount = buyCoinData.amount.formatMax6 ?? '0';

            return [
              SliverToBoxAdapter(
                child: SwapDetailsCard(
                  sellCoins: sellCoins,
                  sellNetwork: sellNetwork,
                  buyCoins: buyCoins,
                  buyNetwork: buyNetwork,
                  sellAmount: sellAmount,
                  buyAmount: buyAmount,
                  swapType: SwapQuoteInfoType.bridge,
                  priceForSellTokenInBuyToken: 1,
                  sellCoinAbbreviation: sellCoins.abbreviation,
                  buyCoinAbbreviation: buyCoins.abbreviation,
                  slippage: null,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: 20.s),
              ),
            ];
          },
          loading: () => loader,
          error: (error, stack) => loader,
        ),
        SliverToBoxAdapter(
          child: ScreenSideOffset.small(
            child: Column(
              children: [
                ActionsSection(
                  disableButtons: disableTransactionDetailsButtons,
                  onViewOnExplorer: onViewOnExplorer,
                  onShare: () => shareContent(selectedTransaction.transactionExplorerUrl),
                ),
                SizedBox(height: 8.s),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ScreenBottomOffset(),
        ),
      ],
    );
  }
}

class _SwapDetailsCardSkeleton extends StatelessWidget {
  const _SwapDetailsCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ContainerSkeleton(
          width: double.infinity,
          height: 140.s,
          margin: EdgeInsets.symmetric(horizontal: 16.s),
        ),
        SizedBox(height: 16.s),
        ContainerSkeleton(
          width: double.infinity,
          height: 100.s,
          margin: EdgeInsets.symmetric(horizontal: 16.s),
        ),
      ],
    );
  }
}

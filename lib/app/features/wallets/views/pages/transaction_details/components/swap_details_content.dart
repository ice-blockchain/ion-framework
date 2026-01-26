// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/skeleton/container_skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/transaction_details.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/providers/swap_display_data_provider.r.dart';
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
    final swapDisplayAsync = ref.watch(
      swapDisplayDataProvider(selectedTransaction.txHash),
    );

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
        ...swapDisplayAsync.when(
          skipLoadingOnReload: true,
          data: (swapDisplayData) {
            if (swapDisplayData == null) return loader;

            return [
              SliverToBoxAdapter(
                child: SwapDetailsCard(
                  sellCoins: swapDisplayData.sellData.coins,
                  sellNetwork: swapDisplayData.sellData.network,
                  buyCoins: swapDisplayData.buyData.coins,
                  buyNetwork: swapDisplayData.buyData.network,
                  sellAmount: swapDisplayData.sellData.amount,
                  buyAmount: swapDisplayData.buyData.amount,
                  swapType: SwapQuoteInfoType.bridge,
                  priceForSellTokenInBuyToken: swapDisplayData.exchangeRate,
                  sellCoinAbbreviation: swapDisplayData.sellData.coins.abbreviation,
                  buyCoinAbbreviation: swapDisplayData.buyData.coins.abbreviation,
                  slippage: null,
                  hideBuyAmount: swapDisplayData.hideBuyAmount,
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

// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/skeleton/container_skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/expected_swap_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_details.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
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

            final sellData = _extractSwapSideData(swap.fromTransaction, swap.expectedSellData);
            final buyData = _extractSwapSideData(swap.toTransaction, swap.expectedBuyData);

            if (sellData.coins == null ||
                sellData.network == null ||
                buyData.coins == null ||
                buyData.network == null) {
              return loader;
            }

            return [
              SliverToBoxAdapter(
                child: SwapDetailsCard(
                  sellCoins: sellData.coins!,
                  sellNetwork: sellData.network!,
                  buyCoins: buyData.coins!,
                  buyNetwork: buyData.network!,
                  sellAmount: sellData.amount,
                  buyAmount: buyData.amount,
                  swapType: SwapQuoteInfoType.bridge,
                  priceForSellTokenInBuyToken: swap.exchangeRate,
                  sellCoinAbbreviation: sellData.coins!.abbreviation,
                  buyCoinAbbreviation: buyData.coins!.abbreviation,
                  slippage: null,
                  hideBuyAmount: swap.toTransaction == null,
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

({CoinsGroup? coins, NetworkData? network, String amount}) _extractSwapSideData(
  TransactionDetails? transaction,
  ExpectedSwapData? expectedData,
) {
  if (transaction != null) {
    final coinData = transaction.assetData.mapOrNull(coin: (coin) => coin);
    if (coinData != null) {
      return (
        coins: coinData.coinsGroup,
        network: transaction.network,
        amount: coinData.amount.formatMax6 ?? '0',
      );
    }
  }

  if (expectedData != null) {
    final amount = _formatExpectedAmount(expectedData);
    return (coins: expectedData.coinsGroup, network: expectedData.network, amount: amount);
  }

  return (coins: null, network: null, amount: '0');
}

String _formatExpectedAmount(ExpectedSwapData expectedData) {
  try {
    final coin = expectedData.coinsGroup.coins
        .where((c) => c.coin.network.id == expectedData.network.id)
        .firstOrNull;
    if (coin == null) return '0';
    final decimals = coin.coin.decimals;
    final bigAmount = BigInt.parse(expectedData.amount);
    final divisor = BigInt.from(10).pow(decimals);
    final doubleAmount = bigAmount / divisor;
    return doubleAmount.formatMax6 ?? '0';
  } catch (e) {
    return '0';
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

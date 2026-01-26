// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/expected_swap_data.f.dart';
import 'package:ion/app/features/wallets/model/swap_display_data.f.dart';
import 'package:ion/app/features/wallets/model/swap_side_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_details.f.dart';
import 'package:ion/app/features/wallets/providers/swap_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_display_data_provider.r.g.dart';

@riverpod
Future<SwapDisplayData?> swapDisplayData(Ref ref, String partTxHash) async {
  final swap = await ref.watch(swapDetailsProvider(partTxHash).future);
  if (swap == null) return null;

  final sellData = _extractSwapSideData(swap.fromTransaction, swap.expectedSellData);
  final buyData = _extractSwapSideData(swap.toTransaction, swap.expectedBuyData);

  if (sellData == null || buyData == null) return null;

  return SwapDisplayData(
    sellData: sellData,
    buyData: buyData,
    exchangeRate: swap.exchangeRate,
    hideBuyAmount: swap.toTransaction == null,
  );
}

SwapSideData? _extractSwapSideData(
  TransactionDetails? transaction,
  ExpectedSwapData? expectedData,
) {
  if (transaction != null) {
    final coinData = transaction.assetData.mapOrNull(coin: (coin) => coin);
    if (coinData != null) {
      return SwapSideData(
        coins: coinData.coinsGroup,
        network: transaction.network,
        amount: coinData.amount.formatMax6 ?? '0',
      );
    }
  }

  if (expectedData != null) {
    final amount = _formatExpectedAmount(expectedData);
    return SwapSideData(
      coins: expectedData.coinsGroup,
      network: expectedData.network,
      amount: amount,
    );
  }

  return null;
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

// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/coins_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'filtered_swap_coins_provider.r.g.dart';

@riverpod
Future<List<CoinsGroup>> filteredSwapCoins(Ref ref) async {
  final allCoins = await ref.watch(coinsInWalletProvider.future);

  // Filter to only include coins where at least one network has a wallet
  return allCoins.where((coinGroup) {
    if (coinGroup.abbreviation == 'ION') {
      return false;
    }

    return coinGroup.coins.any((coin) => coin.walletId != null);
  }).toList();
}

// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/repository/swaps_repository.r.dart';
import 'package:ion/app/features/wallets/model/swap_details.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_provider.r.g.dart';

@riverpod
Future<SwapDetails?> swapDetails(Ref ref, String partTxHash) async {
  final repository = await ref.watch(swapsRepositoryProvider.future);
  final walletViewData = await ref.watch(currentWalletViewDataProvider.future);

  return repository.getSwapDetails(
    txHash: partTxHash,
    walletViewId: walletViewData.id,
    walletViewName: walletViewData.name,
  );
}

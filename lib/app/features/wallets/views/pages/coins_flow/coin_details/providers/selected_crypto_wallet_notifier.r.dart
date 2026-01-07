// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/providers/synced_coins_by_symbol_group_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/model/selected_crypto_wallet_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/network_selector_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_crypto_wallet_notifier.r.g.dart';

@riverpod
class SelectedCryptoWalletNotifier extends _$SelectedCryptoWalletNotifier {
  // TODO: Remove hardcoded wallets when real data is available
  // static const List<String> _wallets = [
  //   '0x736ce4593eb7bc5ec1c640cff00a527c80928a0c',
  //   '0xa82dbf68fc2822d9d4f431753fded2c904539cea',
  // ];

  @override
  SelectedCryptoWalletData build({required String symbolGroup}) {
    final network = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup).select(
        (state) => state?.selected.whenOrNull(network: (network) => network),
      ),
    );

    if (network == null) {
      return const SelectedCryptoWalletData(wallets: []);
    }

    final coins = ref.watch(syncedCoinsBySymbolGroupProvider(symbolGroup)).valueOrNull ?? [];

    final walletAddresses = coins
        .where((coin) => coin.coin.network == network)
        .map((coin) => coin.walletAddress)
        .nonNulls
        .toSet()
        .toList();

    return SelectedCryptoWalletData(
      selectedWallet: walletAddresses.isNotEmpty ? walletAddresses.first : null,
      wallets: walletAddresses,
    );
  }

  set selectedWallet(String wallet) => state = state.copyWith(selectedWallet: wallet);
}

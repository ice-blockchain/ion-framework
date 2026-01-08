// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/model/selected_crypto_wallet_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/network_selector_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_crypto_wallet_notifier.r.g.dart';

@riverpod
class SelectedCryptoWalletNotifier extends _$SelectedCryptoWalletNotifier {
  @override
  SelectedCryptoWalletData build({required String symbolGroup}) {
    // ignore: avoid_print
    print('Denis[${DateTime.now()}] SelectedCryptoWalletNotifier.build() called');

    final network = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup).select(
        (state) => state?.selected.whenOrNull(network: (network) => network),
      ),
    );

    // ignore: avoid_print
    print('Denis[${DateTime.now()}] SelectedCryptoWalletNotifier: network=$network');

    if (network == null) {
      // ignore: avoid_print
      print('Denis[${DateTime.now()}] SelectedCryptoWalletNotifier returning empty (no network)');
      return SelectedCryptoWalletData.empty();
    }

    final walletView = ref.watch(
      currentWalletViewDataProvider.select((asyncValue) => asyncValue.valueOrNull),
    );

    if (walletView == null) {
      // ignore: avoid_print
      print(
          'Denis[${DateTime.now()}] SelectedCryptoWalletNotifier returning empty (no walletView)');
      return SelectedCryptoWalletData.empty();
    }

    final connectedAddresses = walletView.coins
        .where((coin) => coin.coin.network == network)
        .map((coin) => coin.walletAddress)
        .nonNulls
        .toSet();

    final relatedAddresses = ref.watch(
      walletsNotifierProvider.select(
        (asyncValue) =>
            asyncValue.valueOrNull
                ?.where(
                  (wallet) => wallet.name == walletView.id && wallet.network == network.id,
                )
                .map((wallet) => wallet.address)
                .nonNulls
                .toSet() ??
            <String>{},
      ),
    );

    final wallets = {...connectedAddresses, ...relatedAddresses}.toList();

    if (wallets.isEmpty) {
      // ignore: avoid_print
      print('Denis[${DateTime.now()}] SelectedCryptoWalletNotifier returning empty (no wallets)');
      return SelectedCryptoWalletData.empty();
    }

    // ignore: avoid_print
    print(
      'Denis[${DateTime.now()}] SelectedCryptoWalletNotifier returning: '
      'wallets=${wallets.length}, selected=${wallets.first}',
    );

    return SelectedCryptoWalletData(
      wallets: wallets,
      selectedWallet: wallets.first,
    );
  }

  set selectedWallet(String wallet) {
    // ignore: avoid_print
    print('Denis[${DateTime.now()}] SelectedCryptoWalletNotifier.selectedWallet setter: $wallet');
    if (state.wallets.contains(wallet)) {
      state = state.copyWith(selectedWallet: wallet);
    }
  }
}

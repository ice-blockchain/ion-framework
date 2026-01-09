// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/model/selected_crypto_wallet_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/network_selector_notifier.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_crypto_wallet_notifier.r.g.dart';

@riverpod
class SelectedCryptoWalletNotifier extends _$SelectedCryptoWalletNotifier {
  @override
  SelectedCryptoWalletData build({required String symbolGroup}) {
    final network = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup).select(
        (state) => state?.selected.whenOrNull(network: (network) => network),
      ),
    );

    if (network == null) {
      return SelectedCryptoWalletData.empty();
    }

    final walletView = ref.watch(currentWalletViewDataProvider).valueOrNull;

    if (walletView == null) {
      return SelectedCryptoWalletData.empty();
    }

    final connectedWallets = ref
            .watch(walletViewCryptoWalletsProvider(walletViewId: walletView.id))
            .valueOrNull
            ?.where((wallet) => wallet.address != null && wallet.network == network.id)
            .toSet() ??
        {};

    if (connectedWallets.isEmpty) {
      return SelectedCryptoWalletData.empty();
    }

    final relatedWallets = ref.watch(
      walletsNotifierProvider.select(
        (asyncValue) =>
            asyncValue.valueOrNull
                ?.where(
                  (wallet) =>
                      wallet.name == walletView.id &&
                      wallet.network == network.id &&
                      wallet.address != null,
                )
                .toSet() ??
            {},
      ),
    );

    final disconnectedWallets = relatedWallets.difference(connectedWallets);
    final wallets = [
      ...connectedWallets,
      ...disconnectedWallets,
    ];

    if (wallets.isEmpty) {
      return SelectedCryptoWalletData.empty();
    }

    return SelectedCryptoWalletData(
      wallets: wallets,
      selectedWallet: wallets.first,
      disconnectedWalletsToDisplay: disconnectedWallets.toList(),
    );
  }

  set selectedWallet(Wallet wallet) {
    if (state.wallets.contains(wallet)) {
      state = state.copyWith(selectedWallet: wallet);
    }
  }
}

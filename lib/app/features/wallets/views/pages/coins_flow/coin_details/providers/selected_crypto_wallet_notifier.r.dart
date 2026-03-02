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
  List<Wallet>? _cachedConnectedWallets;
  List<Wallet>? _cachedAllWallets;
  String? _cachedWalletViewId;

  @override
  Future<SelectedCryptoWalletData> build({required String symbolGroup}) async {
    final network = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup).select(
        (asyncState) => asyncState.valueOrNull?.selected.whenOrNull(network: (network) => network),
      ),
    );

    if (_cachedConnectedWallets == null || _cachedAllWallets == null) {
      final walletView = await ref.read(currentWalletViewDataProvider.future);
      _cachedWalletViewId = walletView.id;

      _cachedConnectedWallets = await ref.read(
        walletViewCryptoWalletsProvider(walletViewId: walletView.id).future,
      );

      _cachedAllWallets = await ref.read(walletsNotifierProvider.future);
    }

    if (network == null) {
      return SelectedCryptoWalletData.empty();
    }

    final connectedWallets = _cachedConnectedWallets!
        .where((wallet) => wallet.address != null && wallet.network == network.id)
        .toSet();

    if (connectedWallets.isEmpty) {
      return SelectedCryptoWalletData.empty();
    }

    final relatedWallets = _cachedAllWallets!
        .where(
          (wallet) =>
              wallet.name == _cachedWalletViewId &&
              wallet.network == network.id &&
              wallet.address != null,
        )
        .toSet();

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
    final currentState = state.valueOrNull;
    if (currentState != null && currentState.wallets.contains(wallet)) {
      state = AsyncData(currentState.copyWith(selectedWallet: wallet));
    }
  }
}

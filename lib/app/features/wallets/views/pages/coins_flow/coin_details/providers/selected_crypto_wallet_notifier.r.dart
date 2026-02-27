// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/model/selected_crypto_wallet_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/network_selector_notifier.r.dart';
import 'package:ion/app/services/logger/logger.dart';
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
    final stopwatch = Stopwatch()..start();
    Logger.info('[Provider] SelectedCryptoWalletNotifier build START');

    final network = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup).select(
        (asyncState) => asyncState.valueOrNull?.selected.whenOrNull(network: (network) => network),
      ),
    );
    Logger.info('[Provider] SelectedCryptoWalletNotifier after networkSelector: ${stopwatch.elapsedMilliseconds}ms, network: ${network?.id ?? "null"}');

    // Always load wallet data (even when network is null) to warm up cache for first tap
    if (_cachedConnectedWallets == null || _cachedAllWallets == null) {
      final walletView = await ref.read(currentWalletViewDataProvider.future);
      _cachedWalletViewId = walletView.id;
      Logger.info('[Provider] SelectedCryptoWalletNotifier after walletView: ${stopwatch.elapsedMilliseconds}ms');

      _cachedConnectedWallets = await ref.read(
        walletViewCryptoWalletsProvider(walletViewId: walletView.id).future,
      );
      Logger.info('[Provider] SelectedCryptoWalletNotifier after connectedWallets (cached): ${stopwatch.elapsedMilliseconds}ms');

      _cachedAllWallets = await ref.read(walletsNotifierProvider.future);
      Logger.info('[Provider] SelectedCryptoWalletNotifier after allWallets (cached): ${stopwatch.elapsedMilliseconds}ms');
    } else {
      Logger.info('[Provider] SelectedCryptoWalletNotifier using cached wallets: ${stopwatch.elapsedMilliseconds}ms');
    }

    if (network == null) {
      Logger.info('[Provider] SelectedCryptoWalletNotifier COMPLETE (no network, cache warmed): ${stopwatch.elapsedMilliseconds}ms');
      return SelectedCryptoWalletData.empty();
    }

    // Fast local filtering
    final connectedWallets = _cachedConnectedWallets!
        .where((wallet) => wallet.address != null && wallet.network == network.id)
        .toSet();

    if (connectedWallets.isEmpty) {
      Logger.info('[Provider] SelectedCryptoWalletNotifier COMPLETE (no connected): ${stopwatch.elapsedMilliseconds}ms');
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
    Logger.info('[Provider] SelectedCryptoWalletNotifier after relatedWallets: ${stopwatch.elapsedMilliseconds}ms');

    final disconnectedWallets = relatedWallets.difference(connectedWallets);
    final wallets = [
      ...connectedWallets,
      ...disconnectedWallets,
    ];

    if (wallets.isEmpty) {
      Logger.info('[Provider] SelectedCryptoWalletNotifier COMPLETE (empty wallets): ${stopwatch.elapsedMilliseconds}ms');
      return SelectedCryptoWalletData.empty();
    }

    Logger.info('[Provider] SelectedCryptoWalletNotifier COMPLETE: ${stopwatch.elapsedMilliseconds}ms');
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

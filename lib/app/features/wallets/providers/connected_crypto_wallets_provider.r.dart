// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connected_crypto_wallets_provider.r.g.dart';

/// Returns all connected crypto wallets to the WalletViews
@riverpod
Future<List<Wallet>> connectedCryptoWallets(Ref ref) async {
  final walletViews = await ref.watch(walletViewsDataNotifierProvider.future);
  final cryptoWallets = await ref.watch(walletsNotifierProvider.future);

  final walletIds =
      walletViews.expand((view) => view.coins).map((coin) => coin.walletId).nonNulls.toList();

  return cryptoWallets.filterByIds(walletIds);
}

/// Returns crypto wallets of the specified WalletView. If the [walletViewId] is not provided,
/// the current WalletView will be used.
@riverpod
Future<List<Wallet>> walletViewCryptoWallets(Ref ref, {String? walletViewId}) async {
  final walletView = walletViewId == null
      ? await ref.watch(currentWalletViewDataProvider.future)
      : await ref.watch(walletViewByIdProvider(id: walletViewId).future);

  final cryptoWallets = await ref.watch(walletsNotifierProvider.future);

  final walletIds = walletView.coins.map((coin) => coin.walletId).nonNulls.toList();

  return cryptoWallets.filterByIds(walletIds);
}

/// Returns crypto wallets of the main WalletView
@riverpod
Future<List<Wallet>> mainCryptoWallets(Ref ref) async {
  final mainWalletView = await ref.watch(mainWalletViewProvider.future);
  final cryptoWallets = await ref.watch(walletsNotifierProvider.future);

  final walletIds = mainWalletView.coins.map((coin) => coin.walletId).nonNulls.toList();

  return cryptoWallets.filterByIds(walletIds);
}

extension on List<Wallet> {
  List<Wallet> filterByIds(List<String> ids) {
    return where((cryptoWallet) => ids.contains(cryptoWallet.id)).toList();
  }
}

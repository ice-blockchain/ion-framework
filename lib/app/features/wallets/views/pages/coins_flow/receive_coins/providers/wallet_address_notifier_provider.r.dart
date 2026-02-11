// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart' as ion;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_address_notifier_provider.r.g.dart';

@riverpod
class WalletAddressNotifier extends _$WalletAddressNotifier {
  @override
  FutureOr<void> build() {}

  Future<String?> createWallet({
    required NetworkData network,
    required ion.OnVerifyIdentity<ion.Wallet> onVerifyIdentity,
    String? walletViewId,
  }) async {
    state = const AsyncValue.loading();

    String? walletAddress;
    state = await AsyncValue.guard(() async {
      final ionIdentity = await ref.read(ionIdentityClientProvider.future);
      final viewId =
          walletViewId != null ? walletViewId : await ref.read(currentWalletViewIdProvider.future);

      final result = await ionIdentity.wallets.createWallet(
        network: network.id,
        walletViewId: viewId,
        onVerifyIdentity: onVerifyIdentity,
      );

      await ref.read(walletsNotifierProvider.notifier).addWallet(result);

      walletAddress = result.address;
    });

    return walletAddress;
  }

  Future<String?> loadWalletAddress({
    required NetworkData? network,
    required CoinsGroup? coinsGroup,
  }) async {
    final coin = coinsGroup?.coins.firstWhereOrNull(
      (coinInWallet) => coinInWallet.coin.network == network,
    );

    // Get address from CoinInWalletData if exists
    if (coin?.walletAddress != null) return coin!.walletAddress;

    final currentWalletViewId = await ref.read(currentWalletViewIdProvider.future);
    final wallets = await ref.read(
      walletViewCryptoWalletsProvider(walletViewId: currentWalletViewId).future,
    );

    // Try to find wallet by coin's walletId
    var wallet = wallets.firstWhereOrNull((w) => w.id == coin?.walletId);
    if (wallet?.address != null) return wallet!.address;

    // Try to find wallet by network id
    wallet = network != null ? wallets.firstWhereOrNull((w) => w.network == network.id) : null;

    return wallet?.address;
  }
}

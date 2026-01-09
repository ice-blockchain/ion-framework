// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:ion/app/features/wallets/model/coin_balance_state.f.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/synced_coins_by_symbol_group_provider.r.dart';
import 'package:ion/app/features/wallets/utils/wallet_asset_utils.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/network_selector_notifier.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/selected_crypto_wallet_notifier.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart' as ion;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'balance_provider.r.g.dart';

@riverpod
class CoinBalanceNotifier extends _$CoinBalanceNotifier {
  @override
  CoinBalanceState build({required String symbolGroup}) {
    final cryptoWalletData = ref.watch(
      selectedCryptoWalletNotifierProvider(symbolGroup: symbolGroup),
    );

    final currentNetwork = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup).select(
        (state) => state?.selected.whenOrNull(network: (network) => network),
      ),
    );

    final isAllNetworks = currentNetwork == null;
    final hasDisconnectedWallets = cryptoWalletData.disconnectedWalletsToDisplay.isNotEmpty;

    final connectedBalance = _calculateConnectedBalance(symbolGroup, currentNetwork);

    if (!hasDisconnectedWallets) return connectedBalance;

    // Scenario 1: All networks selected + has disconnected wallets
    if (isAllNetworks && hasDisconnectedWallets) {
      unawaited(
        _loadDisconnectedWalletBalances(
          symbolGroup: symbolGroup,
          disconnectedWallets: cryptoWalletData.disconnectedWalletsToDisplay,
        ),
      );
      return connectedBalance;
    }

    final isDisconnectedWalletSelected = currentNetwork != null &&
        cryptoWalletData.disconnectedWalletsToDisplay.contains(cryptoWalletData.selectedWallet);
    // Scenario 2: Specific network + disconnected wallet selected
    if (isDisconnectedWalletSelected) {
      unawaited(
        _loadDisconnectedWalletBalance(
          network: currentNetwork,
          symbolGroup: symbolGroup,
          wallet: cryptoWalletData.selectedWallet!,
        ),
      );
      // Return empty state till the correct balance will be loaded
      return const CoinBalanceState();
    }

    return connectedBalance;
  }

  CoinBalanceState _calculateConnectedBalance(
    String symbolGroup,
    NetworkData? currentNetwork,
  ) {
    final coinsValue = ref.watch(syncedCoinsBySymbolGroupProvider(symbolGroup));
    final coins = coinsValue.valueOrNull ?? <CoinInWalletData>[];

    final filteredCoins = currentNetwork == null
        ? coins
        : coins
            .where(
              (CoinInWalletData coin) => coin.coin.network.id == currentNetwork.id,
            )
            .toList();

    final totalAmount = filteredCoins.fold<double>(
      0,
      (double sum, CoinInWalletData coin) => sum + coin.amount,
    );
    final totalBalanceUSD = filteredCoins.fold<double>(
      0,
      (double sum, CoinInWalletData coin) => sum + coin.balanceUSD,
    );

    return CoinBalanceState(amount: totalAmount, balanceUSD: totalBalanceUSD);
  }

  Future<void> _loadDisconnectedWalletBalances({
    required String symbolGroup,
    required List<ion.Wallet> disconnectedWallets,
  }) async {
    try {
      final client = await ref.read(ionIdentityClientProvider.future);

      final coins = await ref.read(syncedCoinsBySymbolGroupProvider(symbolGroup).future);

      var totalAmount = 0.0;
      var totalBalanceUSD = 0.0;

      for (final wallet in disconnectedWallets) {
        final coin = coins.firstWhereOrNull((coin) => coin.coin.network.id == wallet.network)?.coin;

        if (coin != null) {
          final balance = await _loadWalletBalance(
            client: client,
            wallet: wallet,
            coin: coin,
          );
          totalAmount += balance.amount;
          totalBalanceUSD += balance.balanceUSD;
        }
      }

      // State should already contain the balances for the connected wallets
      state = state.copyWith(
        amount: state.amount + totalAmount,
        balanceUSD: state.balanceUSD + totalBalanceUSD,
      );
    } catch (e, st) {
      Logger.error('Failed to load disconnected wallet balances: $e', stackTrace: st);
    }
  }

  Future<void> _loadDisconnectedWalletBalance({
    required ion.Wallet wallet,
    required String symbolGroup,
    required NetworkData network,
  }) async {
    try {
      final client = await ref.read(ionIdentityClientProvider.future);
      final coins = await ref.read(syncedCoinsBySymbolGroupProvider(symbolGroup).future);
      final coin = coins.firstWhereOrNull((coin) => coin.coin.network.id == wallet.network)?.coin;

      if (coin != null) {
        final balance = await _loadWalletBalance(
          client: client,
          wallet: wallet,
          coin: coin,
        );
        state = balance;
      }
    } catch (e, st) {
      Logger.error('Failed to load disconnected wallet balance: $e', stackTrace: st);
    }
  }

  Future<CoinBalanceState> _loadWalletBalance({
    required CoinData coin,
    required ion.Wallet wallet,
    required ion.IONIdentityClient client,
  }) async {
    final walletAssets = await client.wallets.getWalletAssets(wallet.id);

    final asset = getAssociatedWalletAsset(walletAssets.assets, coin);

    // We were unable to find the coin asset, return empty state with 0 balance.
    if (asset == null) return const CoinBalanceState();

    final parsedBalance = double.tryParse(asset.balance) ?? 0;
    final amount = parsedBalance / pow(10, asset.decimals);
    final balanceUSD = amount * coin.priceUSD;

    return CoinBalanceState(amount: amount, balanceUSD: balanceUSD);
  }
}

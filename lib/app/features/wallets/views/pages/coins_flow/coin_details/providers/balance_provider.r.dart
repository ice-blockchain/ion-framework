// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

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
  final Map<String, CoinBalanceState> _walletBalanceCache = {};
  String? _loadingWalletId;

  @override
  CoinBalanceState build({required String symbolGroup}) {
    final coins = ref.watch(syncedCoinsBySymbolGroupProvider(symbolGroup)).valueOrNull;

    ref.listen(
      syncedCoinsBySymbolGroupProvider(symbolGroup),
      (_, next) {
        final updatedCoins = next.valueOrNull;
        if (updatedCoins == null) return;

        for (final coinInWallet in updatedCoins) {
          final walletId = coinInWallet.walletId;
          if (walletId == null) continue;

          final newState = CoinBalanceState(
            amount: coinInWallet.amount,
            balanceUSD: coinInWallet.balanceUSD,
          );
          if (_walletBalanceCache[walletId] != newState) {
            _walletBalanceCache[walletId] = newState;
          }
        }
      },
      fireImmediately: true,
    );

    final currentNetwork = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup).select(
        (asyncState) => asyncState.valueOrNull?.selected.whenOrNull(network: (network) => network),
      ),
    );

    final isAllNetworks = currentNetwork == null;

    // Scenario 1: All networks selected - return connected balance
    if (isAllNetworks) {
      return _calculateConnectedBalance(currentNetwork, coins);
    }

    // Scenario 2: Specific network selected - get selected wallet's balance
    final cryptoWalletData = ref.watch(
      selectedCryptoWalletNotifierProvider(symbolGroup: symbolGroup),
    );

    final selectedWallet = cryptoWalletData.selectedWallet;

    if (selectedWallet != null && _walletBalanceCache.containsKey(selectedWallet.id)) {
      return _walletBalanceCache[selectedWallet.id]!;
    }

    // Fallback: calculate connected balance or load disconnected
    final connectedBalance = _calculateConnectedBalance(currentNetwork, coins);

    final hasDisconnectedWallets = cryptoWalletData.disconnectedWalletsToDisplay.isNotEmpty;
    if (!hasDisconnectedWallets) return connectedBalance;

    final isDisconnectedWalletSelected =
        cryptoWalletData.disconnectedWalletsToDisplay.contains(selectedWallet);

    if (isDisconnectedWalletSelected) {
      if (_loadingWalletId != selectedWallet!.id) {
        unawaited(
          _loadDisconnectedWalletBalance(
            symbolGroup: symbolGroup,
            wallet: selectedWallet,
          ),
        );
      }
      return connectedBalance;
    }

    return connectedBalance;
  }

  CoinBalanceState _calculateConnectedBalance(
    NetworkData? currentNetwork,
    List<CoinInWalletData>? coins,
  ) {
    final coinsList = coins ?? <CoinInWalletData>[];

    var totalAmount = 0.0;
    var totalBalanceUSD = 0.0;

    for (final coin in coinsList) {
      if (currentNetwork == null || coin.coin.network.id == currentNetwork.id) {
        totalAmount += coin.amount;
        totalBalanceUSD += coin.balanceUSD;
      }
    }

    return CoinBalanceState(amount: totalAmount, balanceUSD: totalBalanceUSD);
  }

  Future<void> _loadDisconnectedWalletBalance({
    required ion.Wallet wallet,
    required String symbolGroup,
  }) async {
    _loadingWalletId = wallet.id;

    try {
      final client = await ref.read(ionIdentityClientProvider.future);
      final coins = await ref.read(syncedCoinsBySymbolGroupProvider(symbolGroup).future);
      final coin = coins.firstWhereOrNull((coin) => coin.coin.network.id == wallet.network)?.coin;

      if (coin != null && _loadingWalletId == wallet.id) {
        final balance = await _loadWalletBalance(
          client: client,
          wallet: wallet,
          coin: coin,
        );

        if (_loadingWalletId == wallet.id) {
          _walletBalanceCache[wallet.id] = balance;
          state = balance;
        }
      }
    } catch (e, st) {
      Logger.error('Failed to load disconnected wallet balance: $e', stackTrace: st);
    } finally {
      if (_loadingWalletId == wallet.id) {
        _loadingWalletId = null;
      }
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

    final balance = calculateBalanceFromAsset(asset, coin);

    return CoinBalanceState(amount: balance.amount, balanceUSD: balance.balanceUSD);
  }
}

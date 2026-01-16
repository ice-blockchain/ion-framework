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
  bool _cacheInitialized = false;

  @override
  CoinBalanceState build({required String symbolGroup}) {
    final currentNetwork = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup).select(
        (asyncState) => asyncState.valueOrNull?.selected.whenOrNull(network: (network) => network),
      ),
    );

    final isAllNetworks = currentNetwork == null;

    // Scenario 1: All networks selected - load all balances and cache them
    if (isAllNetworks) {
      final connectedBalance = _calculateConnectedBalance(symbolGroup, currentNetwork);
      unawaited(_loadAllBalancesAndCache(symbolGroup: symbolGroup));
      return connectedBalance;
    }

    // Scenario 2: Specific network selected - get selected wallet's balance
    final cryptoWalletData = ref.watch(
      selectedCryptoWalletNotifierProvider(symbolGroup: symbolGroup),
    );

    final selectedWallet = cryptoWalletData.selectedWallet;

    // Try to get selected wallet's balance from cache
    if (_cacheInitialized &&
        selectedWallet != null &&
        _walletBalanceCache.containsKey(selectedWallet.id)) {
      return _walletBalanceCache[selectedWallet.id]!;
    }

    // Fallback: calculate connected balance or load disconnected
    final connectedBalance = _calculateConnectedBalance(symbolGroup, currentNetwork);

    final hasDisconnectedWallets = cryptoWalletData.disconnectedWalletsToDisplay.isNotEmpty;
    if (!hasDisconnectedWallets) return connectedBalance;

    final isDisconnectedWalletSelected =
        cryptoWalletData.disconnectedWalletsToDisplay.contains(selectedWallet);

    if (isDisconnectedWalletSelected) {
      unawaited(
        _loadDisconnectedWalletBalance(
          symbolGroup: symbolGroup,
          wallet: selectedWallet!,
        ),
      );
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

  Future<void> _loadAllBalancesAndCache({required String symbolGroup}) async {
    if (_cacheInitialized) return;

    try {
      final coins = await ref.read(syncedCoinsBySymbolGroupProvider(symbolGroup).future);

      // Cache connected wallet balances from synced coins
      for (final coinInWallet in coins) {
        final walletId = coinInWallet.walletId;
        if (walletId != null) {
          _walletBalanceCache[walletId] = CoinBalanceState(
            amount: coinInWallet.amount,
            balanceUSD: coinInWallet.balanceUSD,
          );
        }
      }

      _cacheInitialized = true;
    } catch (e, st) {
      Logger.error('Failed to load all balances and cache: $e', stackTrace: st);
    }
  }

  Future<void> _loadDisconnectedWalletBalance({
    required ion.Wallet wallet,
    required String symbolGroup,
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
        _walletBalanceCache[wallet.id] = balance;
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

    final balance = calculateBalanceFromAsset(asset, coin);

    return CoinBalanceState(amount: balance.amount, balanceUSD: balance.balanceUSD);
  }
}

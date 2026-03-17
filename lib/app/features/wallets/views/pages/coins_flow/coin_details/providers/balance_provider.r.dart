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
  final Set<String> _loadedDisconnectedWalletIds = {};
  late String _networkKey;

  @override
  CoinBalanceState build({required String symbolGroup}) {
    final currentNetwork = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup).select(
        (asyncState) => asyncState.valueOrNull?.selected.whenOrNull(network: (network) => network),
      ),
    );
    final networkKey = currentNetwork?.id ?? CoinBalanceAllNetworksState.allNetworksKey;
    _networkKey = networkKey;

    // Scenario 1: All networks selected - load all balances and cache them
      final connectedBalance = _calculateConnectedBalance(symbolGroup, currentNetwork);
      unawaited(_loadAllBalancesAndCache(symbolGroup: symbolGroup));
      return connectedBalance;
    }

          _loadedDisconnectedWalletIds.clear();
          final newBalances = _calculateAllNetworkBalances(updatedCoins);
          _emitState(newBalances);
        },
        fireImmediately: true,
      )
      ..listen(
        selectedCryptoWalletNotifierProvider(symbolGroup: symbolGroup),
        (_, next) {
          final disconnectedWallets = next.valueOrNull?.disconnectedWalletsToDisplay;
          if (disconnectedWallets == null || disconnectedWallets.isEmpty) return;

          for (final wallet in disconnectedWallets) {
            _loadDisconnectedWalletBalance(wallet: wallet, symbolGroup: symbolGroup);
          }
        },
        fireImmediately: true,
      );

    return CoinBalanceAllNetworksState(
      balancesByNetwork: Map.unmodifiable(balances),
      selectedNetworkKey: networkKey,
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

  void _emitState(Map<String, CoinBalanceState> balances) {
    state = AsyncData(
      CoinBalanceAllNetworksState(
        balancesByNetwork: Map.unmodifiable(balances),
        selectedNetworkKey: _networkKey,
      ),
    );
  }

  Future<void> _loadDisconnectedWalletBalance({
    required ion.Wallet wallet,
    required String symbolGroup,
  }) async {
    try {
      final client = await ref.read(ionIdentityClientProvider.future);
      final coins = await ref.read(syncedCoinsBySymbolGroupProvider(symbolGroup).future);
      final coin = coins.firstWhereOrNull((coin) => coin.coin.network.id == wallet.network)?.coin;

      if (coin == null) return;

      final balance = await _loadWalletBalance(client: client, wallet: wallet, coin: coin);

      final currentBalances = state.valueOrNull?.balancesByNetwork;
      if (currentBalances == null) return;

      final newBalances = Map<String, CoinBalanceState>.from(currentBalances);

      final existingNetworkBalance = newBalances[wallet.network] ?? const CoinBalanceState();
      newBalances[wallet.network] = CoinBalanceState(
        amount: existingNetworkBalance.amount + balance.amount,
        balanceUSD: existingNetworkBalance.balanceUSD + balance.balanceUSD,
      );

      final allBalance =
          newBalances[CoinBalanceAllNetworksState.allNetworksKey] ?? const CoinBalanceState();
      newBalances[CoinBalanceAllNetworksState.allNetworksKey] = CoinBalanceState(
        amount: allBalance.amount + balance.amount,
        balanceUSD: allBalance.balanceUSD + balance.balanceUSD,
      );

      _emitState(newBalances);
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

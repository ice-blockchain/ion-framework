// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:ion/app/features/wallets/model/coin_balance_all_networks_state.f.dart';
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

  @override
  Future<CoinBalanceAllNetworksState> build({required String symbolGroup}) async {
    final currentNetwork = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup).select(
        (asyncState) => asyncState.valueOrNull?.selected.whenOrNull(network: (network) => network),
      ),
    );
    final networkKey = currentNetwork?.id ?? CoinBalanceAllNetworksState.allNetworksKey;

    final coinsCache = await ref.read(syncedCoinsBySymbolGroupNotifierProvider.future);
    final coins = coinsCache[symbolGroup] ?? [];
    final balances = _calculateAllNetworkBalances(coins);

    ref
      ..listen(
        syncedCoinsBySymbolGroupNotifierProvider,
        (_, next) {
          final updatedCoins = next.valueOrNull?[symbolGroup];
          if (updatedCoins == null) return;

          _loadedDisconnectedWalletIds.clear();
          final newBalances = _calculateAllNetworkBalances(updatedCoins);
          _emitState(newBalances, symbolGroup);
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
  }

  Map<String, CoinBalanceState> _calculateAllNetworkBalances(List<CoinInWalletData> coins) {
    final balances = <String, CoinBalanceState>{};

    balances[CoinBalanceAllNetworksState.allNetworksKey] = _calculateBalance(null, coins);

    final networks = coins.map((c) => c.coin.network).toSet();
    for (final network in networks) {
      balances[network.id] = _calculateBalance(network, coins);
    }

    return balances;
  }

  CoinBalanceState _calculateBalance(NetworkData? network, List<CoinInWalletData> coins) {
    var totalAmount = 0.0;
    var totalBalanceUSD = 0.0;

    for (final coin in coins) {
      if (network == null || coin.coin.network.id == network.id) {
        totalAmount += coin.amount;
        totalBalanceUSD += coin.balanceUSD;
      }
    }

    return CoinBalanceState(amount: totalAmount, balanceUSD: totalBalanceUSD);
  }

  void _emitState(Map<String, CoinBalanceState> balances, String symbolGroup) {
    final networkKey = ref
            .read(networkSelectorNotifierProvider(symbolGroup: symbolGroup))
            .valueOrNull
            ?.selected
            .whenOrNull(network: (network) => network.id) ??
        CoinBalanceAllNetworksState.allNetworksKey;

    state = AsyncData(
      CoinBalanceAllNetworksState(
        balancesByNetwork: Map.unmodifiable(balances),
        selectedNetworkKey: networkKey,
      ),
    );
  }

  Future<void> _loadDisconnectedWalletBalance({
    required ion.Wallet wallet,
    required String symbolGroup,
  }) async {
    if (_loadedDisconnectedWalletIds.contains(wallet.id)) return;
    _loadedDisconnectedWalletIds.add(wallet.id);

    try {
      final client = await ref.read(ionIdentityClientProvider.future);
      final coinsCache = await ref.read(syncedCoinsBySymbolGroupNotifierProvider.future);
      final coins = coinsCache[symbolGroup] ?? [];
      final coin = coins.firstWhereOrNull((c) => c.coin.network.id == wallet.network)?.coin;

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

      _emitState(newBalances, symbolGroup);
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

    if (asset == null) return const CoinBalanceState();

    final balance = calculateBalanceFromAsset(asset, coin);

    return CoinBalanceState(amount: balance.amount, balanceUSD: balance.balanceUSD);
  }
}

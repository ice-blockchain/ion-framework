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
  Map<String, CoinBalanceState> _networkBalanceCache = {};
  List<CoinInWalletData>? _cachedCoins;
  final Set<String> _loadedDisconnectedWalletIds = {};
  bool _isInitialized = false;

  @override
  Future<CoinBalanceAllNetworksState> build({required String symbolGroup}) async {
    final currentNetwork = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup).select(
        (asyncState) => asyncState.valueOrNull?.selected.whenOrNull(network: (network) => network),
      ),
    );
    final networkKey = currentNetwork?.id ?? CoinBalanceAllNetworksState.allNetworksKey;

    if (_isInitialized && _networkBalanceCache.containsKey(networkKey)) {
      return CoinBalanceAllNetworksState(
        balancesByNetwork: Map.unmodifiable(_networkBalanceCache),
        selectedNetworkKey: networkKey,
      );
    }

    if (!_isInitialized) {
      _cachedCoins = await ref.read(syncedCoinsBySymbolGroupProvider(symbolGroup).future);
      _preCalculateAllNetworkBalances();
      _isInitialized = true;
    }

    ref
      ..listen(
        syncedCoinsBySymbolGroupProvider(symbolGroup),
        (_, next) {
          final updatedCoins = next.valueOrNull;
          if (updatedCoins == null) return;

          _cachedCoins = updatedCoins;
          _preCalculateAllNetworkBalances();

          final currentNetworkKey = ref
                  .read(networkSelectorNotifierProvider(symbolGroup: symbolGroup))
                  .valueOrNull
                  ?.selected
                  .whenOrNull(network: (network) => network.id) ??
              CoinBalanceAllNetworksState.allNetworksKey;

          state = AsyncData(
            CoinBalanceAllNetworksState(
              balancesByNetwork: Map.unmodifiable(_networkBalanceCache),
              selectedNetworkKey: currentNetworkKey,
            ),
          );
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
      balancesByNetwork: Map.unmodifiable(_networkBalanceCache),
      selectedNetworkKey: networkKey,
    );
  }

  void _preCalculateAllNetworkBalances() {
    if (_cachedCoins == null) return;

    _networkBalanceCache = {};
    _loadedDisconnectedWalletIds.clear();

    _networkBalanceCache[CoinBalanceAllNetworksState.allNetworksKey] =
        _calculateConnectedBalance(null, _cachedCoins);

    final networks = _cachedCoins!.map((c) => c.coin.network).toSet();
    for (final network in networks) {
      _networkBalanceCache[network.id] = _calculateConnectedBalance(network, _cachedCoins);
    }
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
    if (_loadedDisconnectedWalletIds.contains(wallet.id)) return;
    _loadedDisconnectedWalletIds.add(wallet.id);

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

        final existingNetworkBalance =
            _networkBalanceCache[wallet.network] ?? const CoinBalanceState();
        _networkBalanceCache[wallet.network] = CoinBalanceState(
          amount: existingNetworkBalance.amount + balance.amount,
          balanceUSD: existingNetworkBalance.balanceUSD + balance.balanceUSD,
        );

        final allBalance = _networkBalanceCache[CoinBalanceAllNetworksState.allNetworksKey] ??
            const CoinBalanceState();
        _networkBalanceCache[CoinBalanceAllNetworksState.allNetworksKey] = CoinBalanceState(
          amount: allBalance.amount + balance.amount,
          balanceUSD: allBalance.balanceUSD + balance.balanceUSD,
        );

        final currentNetworkKey = ref
                .read(networkSelectorNotifierProvider(symbolGroup: symbolGroup))
                .valueOrNull
                ?.selected
                .whenOrNull(network: (network) => network.id) ??
            CoinBalanceAllNetworksState.allNetworksKey;

        state = AsyncData(
          CoinBalanceAllNetworksState(
            balancesByNetwork: Map.unmodifiable(_networkBalanceCache),
            selectedNetworkKey: currentNetworkKey,
          ),
        );
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

    if (asset == null) return const CoinBalanceState();

    final balance = calculateBalanceFromAsset(asset, coin);

    return CoinBalanceState(amount: balance.amount, balanceUSD: balance.balanceUSD);
  }
}

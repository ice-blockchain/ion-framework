// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:ion/app/features/wallets/model/coin_balance_state.f.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/synced_coins_by_symbol_group_provider.r.dart';
import 'package:ion/app/features/wallets/utils/wallet_asset_utils.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/model/selected_crypto_wallet_data.f.dart';
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
  final Map<String, CoinBalanceState> _networkBalanceCache = {};
  List<CoinInWalletData>? _cachedCoins;
  String? _loadingWalletId;
  bool _isInitialized = false;

  @override
  Future<CoinBalanceState> build({required String symbolGroup}) async {
    final stopwatch = Stopwatch()..start();
    Logger.info('[Provider] CoinBalanceNotifier build START');

    // Watch network changes - this triggers rebuild when network changes
    final currentNetwork = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: symbolGroup).select(
        (asyncState) => asyncState.valueOrNull?.selected.whenOrNull(network: (network) => network),
      ),
    );
    final networkKey = currentNetwork?.id ?? 'ALL';
    Logger.info('[Provider] CoinBalanceNotifier network: $networkKey, elapsed: ${stopwatch.elapsedMilliseconds}ms');

    // If we have cached balance for this network, return it immediately
    if (_isInitialized && _networkBalanceCache.containsKey(networkKey)) {
      final cachedBalance = _networkBalanceCache[networkKey]!;
      Logger.info('[Provider] CoinBalanceNotifier INSTANT from cache: ${stopwatch.elapsedMilliseconds}ms, balance: ${cachedBalance.amount}');
      return cachedBalance;
    }

    // First time initialization - load coins and pre-calculate all balances
    if (!_isInitialized) {
      _cachedCoins = await ref.read(syncedCoinsBySymbolGroupProvider(symbolGroup).future);
      Logger.info('[Provider] CoinBalanceNotifier after syncedCoins: ${stopwatch.elapsedMilliseconds}ms');

      _preCalculateAllNetworkBalances();
      _isInitialized = true;
      Logger.info('[Provider] CoinBalanceNotifier pre-calculated ${_networkBalanceCache.length} network balances: ${stopwatch.elapsedMilliseconds}ms');
    }

    // Listen for coin updates to refresh cache
    ref.listen(
      syncedCoinsBySymbolGroupProvider(symbolGroup),
      (_, next) {
        final updatedCoins = next.valueOrNull;
        if (updatedCoins == null) return;

        _cachedCoins = updatedCoins;
        _preCalculateAllNetworkBalances();
        Logger.info('[Provider] CoinBalanceNotifier: coins updated, re-calculated network balances');

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

    // Return cached balance for this network
    if (_networkBalanceCache.containsKey(networkKey)) {
      final balance = _networkBalanceCache[networkKey]!;
      Logger.info('[Provider] CoinBalanceNotifier COMPLETE (from cache): ${stopwatch.elapsedMilliseconds}ms, balance: ${balance.amount}');
      return balance;
    }

    // Fallback: calculate if somehow not in cache
    final balance = _calculateConnectedBalance(currentNetwork, _cachedCoins);
    _networkBalanceCache[networkKey] = balance;
    Logger.info('[Provider] CoinBalanceNotifier COMPLETE (calculated): ${stopwatch.elapsedMilliseconds}ms, balance: ${balance.amount}');
    return balance;
  }

  void _preCalculateAllNetworkBalances() {
    if (_cachedCoins == null) return;

    // Calculate "All networks" balance
    _networkBalanceCache['ALL'] = _calculateConnectedBalance(null, _cachedCoins);

    // Calculate balance for each network
    final networks = _cachedCoins!.map((c) => c.coin.network).toSet();
    for (final network in networks) {
      _networkBalanceCache[network.id] = _calculateConnectedBalance(network, _cachedCoins);
    }
    Logger.info('[Provider] CoinBalanceNotifier _preCalculateAllNetworkBalances: ${_networkBalanceCache.keys.toList()}');
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
          state = AsyncData(balance);
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

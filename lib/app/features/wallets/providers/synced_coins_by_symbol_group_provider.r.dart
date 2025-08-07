// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_comparator.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'synced_coins_by_symbol_group_provider.r.g.dart';

typedef SyncedCoinsCache = Map<String, List<CoinInWalletData>>;

@riverpod
class SyncedCoinsBySymbolGroupNotifier extends _$SyncedCoinsBySymbolGroupNotifier {
  late final _coinsComparator = CoinsComparator();

  /// Debounce duration for API requests per symbol group
  static const _debounceDuration = Duration(minutes: 1);

  /// Map to track last request time for each symbol group
  final Map<String, DateTime> _lastRequestTimes = {};

  @override
  FutureOr<SyncedCoinsCache> build() async {
    keepAliveWhenAuthenticated(ref);

    // Reset state when isAuthenticated changes
    await ref.watch(authProvider.selectAsync((state) => state.isAuthenticated));
    // Reset state each time the wallet view changes
    await ref.watch(currentWalletViewIdProvider.future);

    // Clear debounce times when provider resets
    Logger.info('Clear _lastRequestTimes');
    _lastRequestTimes.clear();

    return {};
  }

  /// Retrieves coins for a specific symbol group, using cache when available
  Future<List<CoinInWalletData>> getCoins(String symbolGroup) async {
    final cachedData = state.value?[symbolGroup];

    // If we have cached data and should skip due to debounce, return cached data
    if (cachedData != null && _shouldSkipRequest(symbolGroup)) {
      return cachedData;
    }

    // If no cached data, always fetch regardless of debounce
    final updatedCoins = await _fetchAndProcessCoins(symbolGroup);
    _updateRequestTime(symbolGroup);
    _updateCache({symbolGroup: updatedCoins});

    return updatedCoins;
  }

  /// Refreshes coin data for specified symbol groups or all cached groups
  ///
  /// [symbolGroups] - specific groups to refresh, or null for all cached groups
  /// [force] - bypass debounce mechanism (used before coin transactions)
  Future<void> refresh({List<String>? symbolGroups, bool force = false}) async {
    final currentCache = state.valueOrNull ?? {};
    final groupsToUpdate = symbolGroups ?? currentCache.keys.toList();

    final updates = await Future.wait(
      groupsToUpdate.map((group) async {
        // Skip request if debounce is active and force is false
        if (!force && _shouldSkipRequest(group)) {
          final cachedData = currentCache[group];
          if (cachedData != null) {
            return MapEntry(group, cachedData);
          }
        }

        final coins = await _fetchAndProcessCoins(group);
        _updateRequestTime(group);
        return MapEntry(group, coins);
      }),
    );

    _updateCache(Map.fromEntries(updates));
  }

  Future<List<CoinInWalletData>> _fetchAndProcessCoins(String symbolGroup) async {
    final service = await ref.read(coinsServiceProvider.future);
    final coins = await service.getSyncedCoinsBySymbolGroup(symbolGroup);
    final walletCoins = await _getWalletViewCoins();

    return _processCoins(coins, walletCoins);
  }

  Future<List<CoinInWalletData>> _getWalletViewCoins() async {
    return ref.read(currentWalletViewDataProvider.future).then((walletView) => walletView.coins);
  }

  List<CoinInWalletData> _processCoins(
    Iterable<CoinData> coins,
    Iterable<CoinInWalletData> walletCoins,
  ) {
    final result = coins.map((coin) {
      final fromWallet = walletCoins.firstWhereOrNull((e) => e.coin.id == coin.id);
      return fromWallet?.copyWith(coin: coin) ?? CoinInWalletData(coin: coin);
    }).toList();

    return result..sort(_coinsComparator.compareCoins);
  }

  /// Checks if a request should be skipped due to debounce
  bool _shouldSkipRequest(String symbolGroup) {
    final lastRequestTime = _lastRequestTimes[symbolGroup];
    if (lastRequestTime == null) return false;

    final timeSinceLastRequest = DateTime.now().difference(lastRequestTime);
    return timeSinceLastRequest < _debounceDuration;
  }

  /// Updates the last request time for a symbol group
  void _updateRequestTime(String symbolGroup) {
    _lastRequestTimes[symbolGroup] = DateTime.now();
  }

  void _updateCache(Map<String, List<CoinInWalletData>> updates) {
    state = AsyncValue.data({
      ...state.valueOrNull ?? {},
      ...updates,
    });
  }
}

@riverpod
Future<List<CoinInWalletData>> syncedCoinsBySymbolGroup(
  Ref ref,
  String symbolGroup,
) {
  ref.watch(syncedCoinsBySymbolGroupNotifierProvider);

  final notifier = ref.watch(syncedCoinsBySymbolGroupNotifierProvider.notifier);
  return notifier.getCoins(symbolGroup);
}

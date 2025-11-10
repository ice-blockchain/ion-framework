// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_comparator.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'synced_coins_by_symbol_group_provider.r.g.dart';

typedef SyncedCoinsCache = Map<String, List<CoinInWalletData>>;

@riverpod
class SyncedCoinsBySymbolGroupNotifier extends _$SyncedCoinsBySymbolGroupNotifier {
  late final _coinsComparator = CoinsComparator();

  /// Debounce duration for API requests per symbol group
  static const _debounceDuration = Duration(seconds: 30);

  /// Map to track last request time for each symbol group
  /// to avoid re-request of the same symbol group in a short period of time
  final Map<String, DateTime> _lastRequestTimes = {};

  /// Map to track active/pending requests to prevent
  /// concurrent duplicate requests until the first one in the progress
  final Map<String, Future<List<CoinInWalletData>>?> _activeRequests = {};

  @override
  FutureOr<SyncedCoinsCache> build() async {
    keepAliveWhenAuthenticated(ref);

    await ref.watch(authProvider.selectAsync((state) => state.isAuthenticated));
    await ref.watch(currentWalletViewIdProvider.future);

    _lastRequestTimes.clear();
    _activeRequests.clear();

    // Init cache from data we have in the current wallet view
    final walletViewData = await ref.watch(currentWalletViewDataProvider.future);

    final initialCache = <String, List<CoinInWalletData>>{};
    for (final group in walletViewData.coinGroups) {
      initialCache[group.symbolGroup] = group.coins;
    }

    return initialCache;
  }

  Future<List<CoinInWalletData>> getCoins(String symbolGroup) async {
    final cachedData = state.value?[symbolGroup];

    if (cachedData != null) {
      if (_canMakeRequest(symbolGroup)) {
        // Trigger background refresh
        final activeRequest = _activeRequests[symbolGroup];
        if (activeRequest == null) {
          unawaited(_triggerBackgroundRefresh(symbolGroup));
        }
      }

      // Always return cached data immediately if available
      return cachedData;
    }

    // No cache - must wait for first load
    final activeRequest = _activeRequests[symbolGroup];
    if (activeRequest != null) {
      return activeRequest;
    }

    final requestFuture = _fetchAndProcessCoins(symbolGroup);
    _activeRequests[symbolGroup] = requestFuture;

    try {
      final updatedCoins = await requestFuture;
      _updateRequestTime(symbolGroup);
      _updateCache({symbolGroup: updatedCoins});
      return updatedCoins;
    } finally {
      unawaited(_activeRequests.remove(symbolGroup));
    }
  }

  Future<void> _triggerBackgroundRefresh(String symbolGroup) async {
    final requestFuture = _fetchAndProcessCoins(symbolGroup);
    _activeRequests[symbolGroup] = requestFuture;

    try {
      final updatedCoins = await requestFuture;
      _updateRequestTime(symbolGroup);
      _updateCache({symbolGroup: updatedCoins});
    } finally {
      unawaited(_activeRequests.remove(symbolGroup));
    }
  }

  Future<void> refresh({List<String>? symbolGroups, bool force = false}) async {
    final currentCache = state.valueOrNull ?? {};
    final groupsToUpdate = symbolGroups ?? currentCache.keys.toList();

    // Skip refresh if cache is empty and no specific symbol groups provided
    if (symbolGroups == null && currentCache.isEmpty) {
      return;
    }

    final updates = await Future.wait(
      groupsToUpdate.map((group) async {
        // Skip request if we can't make a request (throttled) and force is false
        if (!force && !_canMakeRequest(group)) {
          final cachedData = currentCache[group];
          if (cachedData != null) {
            return MapEntry(group, cachedData);
          }
        }

        // Force refresh: bypass deduplication and debounce
        if (force) {
          unawaited(_activeRequests.remove(group));
          final coins = await _fetchAndProcessCoins(group);
          _updateRequestTime(group);
          return MapEntry(group, coins);
        }

        // Regular refresh: check for active requests to prevent duplicates
        final activeRequest = _activeRequests[group];
        if (activeRequest != null) {
          return MapEntry(group, await activeRequest);
        }

        // Start new request and track it
        final requestFuture = _fetchAndProcessCoins(group);
        _activeRequests[group] = requestFuture;

        try {
          final coins = await requestFuture;
          _updateRequestTime(group);
          return MapEntry(group, coins);
        } finally {
          unawaited(_activeRequests.remove(group));
        }
      }),
    );

    _updateCache(
      Map.fromEntries(updates),
    );
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

  bool _canMakeRequest(String symbolGroup) {
    final lastRequestTime = _lastRequestTimes[symbolGroup];
    if (lastRequestTime == null) return true;

    final timeSinceLastRequest = DateTime.now().difference(lastRequestTime);
    return timeSinceLastRequest >= _debounceDuration;
  }

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

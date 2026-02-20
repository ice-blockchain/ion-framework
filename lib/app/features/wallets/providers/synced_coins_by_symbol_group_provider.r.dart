// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_comparator.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
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

    final previousCache = state.valueOrNull;

    _lastRequestTimes.clear();
    _activeRequests.clear();

    final walletViewData = await ref.watch(currentWalletViewDataProvider.future);

    return _buildCache(walletViewData.coinGroups, previousCache);
  }

  Future<List<CoinInWalletData>> getCoins(String symbolGroup) async {
    final cachedData = state.value?[symbolGroup];

    if (cachedData != null) {
      if (_canMakeRequest(symbolGroup) && _activeRequests[symbolGroup] == null) {
        unawaited(_executeUpdateRequest(symbolGroup));
      }
      return cachedData;
    }

    return _getOrCreateRequest(symbolGroup);
  }

  Future<void> refresh({List<String>? symbolGroups, bool force = false}) async {
    final currentCache = state.valueOrNull ?? {};
    final groupsToUpdate = symbolGroups ?? currentCache.keys.toList();

    if (symbolGroups == null && currentCache.isEmpty) return;

    final updates = await Future.wait(
      groupsToUpdate.map((group) async {
        if (!force && !_canMakeRequest(group)) {
          final cachedData = currentCache[group];
          if (cachedData != null) return MapEntry(group, cachedData);
        }

        if (force) {
          unawaited(_activeRequests.remove(group));
          final coins = await _executeUpdateRequest(group, updateCache: false);
          return MapEntry(group, coins);
        }

        final coins = await _getOrCreateRequest(group);
        return MapEntry(group, coins);
      }),
    );

    _updateCache(Map.fromEntries(updates));
  }

  SyncedCoinsCache _buildCache(
    Iterable<CoinsGroup> coinGroups,
    SyncedCoinsCache? previousCache,
  ) {
    final cache = <String, List<CoinInWalletData>>{};

    for (final group in coinGroups) {
      final previousCoins = previousCache?[group.symbolGroup];
      cache[group.symbolGroup] = previousCoins != null && previousCoins.isNotEmpty
          ? _mergeCoins(previousCoins, group.coins)
          : (group.coins.toList()..sort(_coinsComparator.compareCoins));
    }

    return cache;
  }

  List<CoinInWalletData> _mergeCoins(
    List<CoinInWalletData> cached,
    Iterable<CoinInWalletData> walletViewCoins,
  ) {
    final walletCoinsById = {for (final c in walletViewCoins) c.coin.id: c};
    final merged = cached.map((coin) => walletCoinsById.remove(coin.coin.id) ?? coin).toList()
      ..addAll(walletCoinsById.values)
      ..sort(_coinsComparator.compareCoins);
    return merged;
  }

  Future<List<CoinInWalletData>> _fetchAndProcessCoins(String symbolGroup) async {
    final service = await ref.read(coinsServiceProvider.future);
    final coins = await service.getSyncedCoinsBySymbolGroup(symbolGroup);
    final walletCoins =
        await ref.read(currentWalletViewDataProvider.future).then((walletView) => walletView.coins);

    return _processCoins(coins, walletCoins);
  }

  List<CoinInWalletData> _processCoins(
    Iterable<CoinData> coins,
    Iterable<CoinInWalletData> walletCoins,
  ) {
    return coins.map((coin) {
      final fromWallet = walletCoins.firstWhereOrNull((e) => e.coin.id == coin.id);
      return fromWallet?.copyWith(coin: coin) ?? CoinInWalletData(coin: coin);
    }).toList()
      ..sort(_coinsComparator.compareCoins);
  }

  Future<List<CoinInWalletData>> _executeUpdateRequest(
    String symbolGroup, {
    bool updateCache = true,
  }) async {
    final requestFuture = _fetchAndProcessCoins(symbolGroup);
    _activeRequests[symbolGroup] = requestFuture;

    try {
      final updatedCoins = await requestFuture;
      _lastRequestTimes[symbolGroup] = DateTime.now();
      if (updateCache) {
        _updateCache({symbolGroup: updatedCoins});
      }
      return updatedCoins;
    } finally {
      await _activeRequests.remove(symbolGroup);
    }
  }

  Future<List<CoinInWalletData>> _getOrCreateRequest(String symbolGroup) async {
    final activeRequest = _activeRequests[symbolGroup];
    if (activeRequest != null) return activeRequest;
    return _executeUpdateRequest(symbolGroup);
  }

  bool _canMakeRequest(String symbolGroup) {
    final lastRequestTime = _lastRequestTimes[symbolGroup];
    if (lastRequestTime == null) return true;
    return DateTime.now().difference(lastRequestTime) >= _debounceDuration;
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

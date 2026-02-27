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
import 'package:ion/app/services/logger/logger.dart';
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
    final stopwatch = Stopwatch()..start();
    Logger.info('[SyncedCoins] build() START');

    keepAliveWhenAuthenticated(ref);

    await ref.watch(authProvider.selectAsync((state) => state.isAuthenticated));
    Logger.info('[SyncedCoins] build() after authProvider: ${stopwatch.elapsedMilliseconds}ms');

    await ref.watch(currentWalletViewIdProvider.future);
    Logger.info('[SyncedCoins] build() after walletViewId: ${stopwatch.elapsedMilliseconds}ms');

    final previousCache = state.valueOrNull;
    final hadCache = previousCache != null && previousCache.isNotEmpty;
    Logger.info('[SyncedCoins] build() hadPreviousCache: $hadCache');

    _activeRequests.clear();

    final walletViewData = await ref.watch(currentWalletViewDataProvider.future);
    Logger.info('[SyncedCoins] build() after walletViewData: ${stopwatch.elapsedMilliseconds}ms');

    final cache = _buildCache(walletViewData.coinGroups, previousCache);

    final now = DateTime.now();
    for (final symbolGroup in cache.keys) {
      _lastRequestTimes[symbolGroup] ??= now;
    }
    Logger.info('[SyncedCoins] build() COMPLETE: ${stopwatch.elapsedMilliseconds}ms, cacheKeys: ${cache.keys.toList()}');

    return cache;
  }

  Future<List<CoinInWalletData>> getCoins(String symbolGroup) async {
    final cachedData = state.value?[symbolGroup];

    if (cachedData != null) {
      Logger.info('[SyncedCoins] getCoins($symbolGroup) CACHE HIT, ${cachedData.length} coins');
      if (_canMakeRequest(symbolGroup) && _activeRequests[symbolGroup] == null) {
        Logger.info('[SyncedCoins] getCoins($symbolGroup) triggering background refresh');
        unawaited(_executeUpdateRequest(symbolGroup));
      }
      return cachedData;
    }

    Logger.info('[SyncedCoins] getCoins($symbolGroup) CACHE MISS, fetching...');
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
    final stopwatch = Stopwatch()..start();
    Logger.info('[SyncedCoins] _fetchAndProcessCoins($symbolGroup) START (API CALL)');

    final service = await ref.read(coinsServiceProvider.future);
    Logger.info('[SyncedCoins] _fetchAndProcessCoins($symbolGroup) got service: ${stopwatch.elapsedMilliseconds}ms');

    final coins = await service.getSyncedCoinsBySymbolGroup(symbolGroup);
    Logger.info('[SyncedCoins] _fetchAndProcessCoins($symbolGroup) API returned ${coins.length} coins: ${stopwatch.elapsedMilliseconds}ms');

    final walletCoins =
        await ref.read(currentWalletViewDataProvider.future).then((walletView) => walletView.coins);
    Logger.info('[SyncedCoins] _fetchAndProcessCoins($symbolGroup) got walletCoins: ${stopwatch.elapsedMilliseconds}ms');

    final result = _processCoins(coins, walletCoins);
    Logger.info('[SyncedCoins] _fetchAndProcessCoins($symbolGroup) COMPLETE: ${stopwatch.elapsedMilliseconds}ms');

    return result;
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
    Logger.info('[SyncedCoins] _executeUpdateRequest($symbolGroup) START, updateCache=$updateCache');
    final requestFuture = _fetchAndProcessCoins(symbolGroup);
    _activeRequests[symbolGroup] = requestFuture;

    try {
      final updatedCoins = await requestFuture;
      _lastRequestTimes[symbolGroup] = DateTime.now();
      if (updateCache) {
        _updateCache({symbolGroup: updatedCoins});
        Logger.info('[SyncedCoins] _executeUpdateRequest($symbolGroup) cache updated with ${updatedCoins.length} coins');
      }
      return updatedCoins;
    } finally {
      await _activeRequests.remove(symbolGroup);
      Logger.info('[SyncedCoins] _executeUpdateRequest($symbolGroup) COMPLETE');
    }
  }

  Future<List<CoinInWalletData>> _getOrCreateRequest(String symbolGroup) async {
    final activeRequest = _activeRequests[symbolGroup];
    if (activeRequest != null) {
      Logger.info('[SyncedCoins] _getOrCreateRequest($symbolGroup) reusing active request');
      return activeRequest;
    }
    Logger.info('[SyncedCoins] _getOrCreateRequest($symbolGroup) creating new request');
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
) async {
  final stopwatch = Stopwatch()..start();
  Logger.info('[SyncedCoins] syncedCoinsBySymbolGroup($symbolGroup) START');

  final notifierState = ref.watch(syncedCoinsBySymbolGroupNotifierProvider);
  Logger.info(
    '[SyncedCoins] syncedCoinsBySymbolGroup($symbolGroup) notifier state: '
    'isLoading=${notifierState.isLoading}, hasValue=${notifierState.hasValue}, '
    'elapsed=${stopwatch.elapsedMilliseconds}ms',
  );

  final notifier = ref.watch(syncedCoinsBySymbolGroupNotifierProvider.notifier);
  final coins = await notifier.getCoins(symbolGroup);

  Logger.info(
    '[SyncedCoins] syncedCoinsBySymbolGroup($symbolGroup) COMPLETE: '
    '${coins.length} coins, ${stopwatch.elapsedMilliseconds}ms',
  );

  return coins;
}

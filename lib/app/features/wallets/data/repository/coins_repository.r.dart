// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/dao/coins_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/dao/sync_coins_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coins_repository.r.g.dart';

typedef SyncCoinAfter = ({String coinId, DateTime syncAfter});

@Riverpod(keepAlive: true)
CoinsRepository coinsRepository(Ref ref) => CoinsRepository(
      coinsDao: ref.watch(coinsDaoProvider),
      syncCoinsDao: ref.watch(syncCoinsDaoProvider),
      localStorage: ref.watch(localStorageProvider),
    );

class CoinsRepository {
  CoinsRepository({
    required CoinsDao coinsDao,
    required SyncCoinsDao syncCoinsDao,
    required LocalStorage localStorage,
  })  : _coinsDao = coinsDao,
        _syncCoinsDao = syncCoinsDao,
        _localStorage = localStorage;

  static const _lastSyncTimeKey = 'coins_last_sync_time';
  static const _coinsVersionKey = 'coins_version';

  final CoinsDao _coinsDao;
  final SyncCoinsDao _syncCoinsDao;
  final LocalStorage _localStorage;

  Future<bool> hasSavedCoins() => _coinsDao.hasAny();

  Future<List<CoinData>> searchCoins(String query) => _coinsDao.search(query);

  Future<void> updateCoins(List<Coin> coins) {
    final validCoins = coins.where((coin) => coin.id.isNotEmpty && coin.decimals > 0).toList();
    return _coinsDao.upsertAll(validCoins);
  }

  Future<void> updateCoinSyncQueue(
    Iterable<SyncCoinAfter> syncCoins, {
    bool updateOnlyDifferences = false,
  }) async {
    final syncCoinsInput = syncCoins
        .map(
          (pair) => SyncCoins(coinId: pair.coinId, syncAfter: pair.syncAfter),
        )
        .toList();

    var toInsert = syncCoinsInput;

    if (updateOnlyDifferences) {
      final coinsInQueue = await _syncCoinsDao.getAll();

      final incomingCoinIds = syncCoins.map((e) => e.coinId).toSet();
      final existingCoinIds = coinsInQueue.map((e) => e.coinId).toSet();

      final toDelete = existingCoinIds.difference(incomingCoinIds);
      toInsert = syncCoinsInput.where((e) => !existingCoinIds.contains(e.coinId)).toList();

      if (toDelete.isNotEmpty) {
        await _syncCoinsDao.removeFromQueue(toDelete.toList());
      }
    }

    await _syncCoinsDao.insertAll(toInsert);
  }

  Future<void> removeFromQueue(List<String> coinIds) => _syncCoinsDao.removeFromQueue(coinIds);

  Future<DateTime?> getNextSyncTime() => _syncCoinsDao.getNextSyncTime();

  Future<bool> hasSyncQueue() => _syncCoinsDao.hasAny();

  Future<bool> isSyncQueueReady(Iterable<String> coinIds) async {
    final coinsInQueue = await _syncCoinsDao.getAll();
    final coinIdsInQueue = coinsInQueue.map((e) => e.coinId);
    return const UnorderedIterableEquality<String>().equals(coinIds, coinIdsInQueue);
  }

  Future<void> removeSyncQueue() => _syncCoinsDao.clear();

  /// Returns a list of coins whose data expires after the specified date.
  Future<List<Coin>> getCoinsToSync(DateTime expirationDate) =>
      _syncCoinsDao.getCoinsToSync(expirationDate);

  /// Returns Stream of coins. Expects a list of coins to watch.
  /// If the [coins] list is not provided, all coins will be watched.
  Stream<List<CoinData>> watchCoins([Iterable<String>? coinIds]) => _coinsDao.watch(coinIds);

  /// Returns Future of coins. Expects a list of coins to get.
  /// If the [coins] list is not provided, all coins will be returned.
  Future<List<CoinData>> getCoins([Iterable<String>? coinIds]) => _coinsDao.get(coinIds);

  Future<CoinData?> getCoinById(String coinId) => _coinsDao.getById(coinId);

  Future<CoinData?> getNativeCoin(NetworkData network) => _coinsDao.getNativeCoin(network.id);

  Future<List<CoinData>> getCoinsByFilters({
    Iterable<String>? symbolGroups,
    Iterable<String>? symbols,
    Iterable<String>? networks,
    Iterable<String>? contractAddresses,
  }) =>
      _coinsDao.getByFilters(
        symbolGroups: symbolGroups,
        symbols: symbols,
        networks: networks,
        contractAddresses: contractAddresses,
      );

  int? getLastSyncTime() => _localStorage.getInt(_lastSyncTimeKey);

  int? getCoinsVersion() => _localStorage.getInt(_coinsVersionKey);

  Future<void> setLastSyncTime(int time) => _localStorage.setInt(_lastSyncTimeKey, time);

  Future<void> setCoinsVersion(int version) => _localStorage.setInt(_coinsVersionKey, version);

  Future<Iterable<CoinsGroup>> getCoinGroups({
    int? limit,
    int? offset,
    Iterable<String>? excludeCoinIds,
    Iterable<String>? symbolGroups,
  }) =>
      _coinsDao.getCoinGroups(
        limit: limit,
        offset: offset,
        excludeCoinIds: excludeCoinIds,
        symbolGroups: symbolGroups,
      );
}

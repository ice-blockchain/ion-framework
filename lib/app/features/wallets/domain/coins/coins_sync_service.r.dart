// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/networks_repository.r.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_mapper.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coins_sync_service.r.g.dart';

@Riverpod(keepAlive: true)
Future<CoinsSyncService> coinsSyncService(Ref ref) async {
  return CoinsSyncService(
    ref.watch(coinsRepositoryProvider),
    ref.watch(networksRepositoryProvider),
    await ref.watch(ionIdentityClientProvider.future),
  );
}

class CoinsSyncService {
  CoinsSyncService(
    this._coinsRepository,
    this._networksRepository,
    this._ionIdentityClient,
  );

  static const _timerInterval = Duration(hours: 1);
  static const _syncInterval = Duration(days: 1);
  Timer? _syncTimer;

  final CoinsRepository _coinsRepository;
  final NetworksRepository _networksRepository;
  final IONIdentityClient _ionIdentityClient;

  void startPeriodicSync() {
    stopPeriodicSync();
    _syncTimer = Timer.periodic(_timerInterval, (_) => syncAllCoins());
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> syncAllCoins() async {
    final lastSyncTime = _coinsRepository.getLastSyncTime();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final syncInterval = _syncInterval.inMilliseconds;

    if (lastSyncTime != null && currentTime - lastSyncTime < syncInterval) {
      return;
    }

    final version = _coinsRepository.getCoinsVersion() ?? 0;
    final response = await _ionIdentityClient.coins.getCoins(currentVersion: version);

    if (response.networks.isNotEmpty) {
      await _networksRepository.setAll(
        response.networks.map(NetworkData.fromDTO).toList(),
      );
    }

    if (response.coins.isEmpty) {
      await _saveSyncData(response.version, DateTime.now().millisecondsSinceEpoch);
      return;
    }

    await _coinsRepository.updateCoins(CoinsMapper().fromDtoToDb(response.coins));

    await _saveSyncData(response.version, currentTime);
  }

  Future<void> saveCoinsVersion(int coinsVersion) async {
    await _coinsRepository.setCoinsVersion(coinsVersion);
  }

  Future<bool> hasSavedCoins() => _coinsRepository.hasSavedCoins();

  Future<void> _saveSyncData(int coinsVersion, int lastSyncTime) async {
    await (
      saveCoinsVersion(coinsVersion),
      _coinsRepository.setLastSyncTime(lastSyncTime),
    ).wait;
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_view_coins_catalog_sync_service.r.g.dart';

@riverpod
WalletViewCoinsCatalogSyncService walletViewCoinsCatalogSyncService(Ref ref) {
  return WalletViewCoinsCatalogSyncService(
    coinsRepository: ref.watch(coinsRepositoryProvider),
  );
}

/// Ensures that coins displayed in WalletViews are present in the local coins catalog (Drift).
///
/// WalletViews can be rendered from remote DTOs even if the local catalog is incomplete.
/// This service keeps the catalog in sync by upserting missing coins only.
class WalletViewCoinsCatalogSyncService {
  WalletViewCoinsCatalogSyncService({
    required CoinsRepository coinsRepository,
  }) : _coinsRepository = coinsRepository;

  final CoinsRepository _coinsRepository;

  Future<void> upsertMissingFromWalletViews(Iterable<CoinData> walletViewCoins) async {
    final coinsById = <String, CoinData>{
      for (final coin in walletViewCoins)
        if (coin.id.isNotEmpty) coin.id: coin,
    };

    if (coinsById.isEmpty) return;

    final existing = await _coinsRepository.getCoins(coinsById.keys);
    final existingIds = existing.map((e) => e.id).toSet();

    final missingCoins = <CoinData>[];
    for (final entry in coinsById.entries) {
      if (!existingIds.contains(entry.key)) {
        missingCoins.add(entry.value);
      }
    }

    if (missingCoins.isEmpty) return;

    await _coinsRepository.updateCoins(
      missingCoins.map((coin) => coin.toDB()).toList(),
    );
  }
}

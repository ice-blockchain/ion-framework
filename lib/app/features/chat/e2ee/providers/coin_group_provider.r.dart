// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coin_group_provider.r.g.dart';

/// Provider to find CoinGroup by asset ID across all wallet views
@riverpod
Future<CoinsGroup?> coinGroupByAssetId(Ref ref, String? assetId) async {
  if (assetId == null || assetId.isEmpty) {
    return null;
  }

  // Get all wallet views and search through their coin groups
  final walletViews = await ref.watch(walletViewsDataNotifierProvider.future);

  // Use functional approach similar to connectedCryptoWallets
  final allCoinGroups = walletViews.expand((view) => view.coinGroups);

  return allCoinGroups.firstWhereOrNull(
    (cg) => cg.coins.any((c) => c.coin.id == assetId),
  );
}

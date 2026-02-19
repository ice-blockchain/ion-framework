// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_to_send_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'find_coin_util.r.g.dart';

@riverpod
Future<FindCoinUtil> findCoinUtil(Ref ref) async {
  return FindCoinUtil(
    await ref.watch(coinsServiceProvider.future),
  );
}

class FindCoinUtil {
  FindCoinUtil(this._coinsService);

  final CoinsService _coinsService;

  Future<CoinData?> findCoinDataForNetwork({
    required NetworkData network,
    required CoinAssetToSendData coin,
  }) async {
    return findCoinDataForNetworkByCoinsGroup(
      network: network,
      coinsGroup: coin.coinsGroup,
    );
  }

  Future<CoinData?> findCoinDataForNetworkByCoinsGroup({
    required NetworkData network,
    required CoinsGroup coinsGroup,
  }) async {
    final existingOption = coinsGroup.coins.firstWhereOrNull(
      (e) => e.coin.network == network,
    );

    return existingOption?.coin ??
        await _getCoinDataForNetwork(
          network: network,
          symbolGroup: coinsGroup.symbolGroup,
          abbreviation: coinsGroup.abbreviation,
        );
  }

  Future<CoinData?> _getCoinDataForNetwork({
    required NetworkData network,
    required String symbolGroup,
    required String abbreviation,
  }) async {
    final coins = await _coinsService.getCoinsByFilters(
      network: network,
      symbolGroup: symbolGroup,
    );

    return coins.firstWhereOrNull((e) => e.abbreviation == abbreviation) ?? coins.firstOrNull;
  }
}

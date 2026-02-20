// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/coins/models/coin.f.dart';
import 'package:ion_identity_client/src/coins/models/coins_response.f.dart';
import 'package:ion_identity_client/src/coins/services/get_coins/data_sources/get_coins_data_source.dart';

class GetCoinsService {
  GetCoinsService({
    required GetCoinsDataSource getCoinsDataSource,
  }) : _getCoinsDataSource = getCoinsDataSource;

  final GetCoinsDataSource _getCoinsDataSource;

  Future<CoinsResponse> getCoins({
    required String username,
    required String userId,
    required int currentVersion,
  }) {
    return _getCoinsDataSource.getCoins(
      username: username,
      userId: userId,
      currentVersion: currentVersion,
    );
  }

  Future<List<Coin>> syncCoins({
    required String username,
    required Set<String> symbolGroups,
  }) {
    return _getCoinsDataSource.syncCoins(
      username: username,
      symbolGroups: symbolGroups,
    );
  }

  Future<List<Coin>> getCoinsBySymbolGroup({
    required String username,
    required String userId,
    required String symbolGroup,
  }) {
    return _getCoinsDataSource.getCoinsBySymbolGroup(
      userId: userId,
      username: username,
      symbolGroup: symbolGroup,
    );
  }

  Future<List<Coin>> searchCoins({
    required String username,
    required String keyword,
    int limit = 10,
    int offset = 0,
  }) {
    return _getCoinsDataSource.searchCoins(
      username: username,
      keyword: keyword,
      limit: limit,
      offset: offset,
    );
  }
}

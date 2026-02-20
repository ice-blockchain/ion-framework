// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/auth/services/extract_user_id/extract_user_id_service.dart';
import 'package:ion_identity_client/src/coins/models/coin.f.dart';
import 'package:ion_identity_client/src/coins/models/coins_response.f.dart';
import 'package:ion_identity_client/src/coins/services/get_coin_data/get_coin_data_service.dart';
import 'package:ion_identity_client/src/coins/services/get_coins/get_coins_service.dart';

class IONIdentityCoins {
  IONIdentityCoins({
    required this.username,
    required GetCoinsService getCoinsService,
    required GetCoinDataService getCoinDataService,
    required ExtractUserIdService extractUserIdService,
  })  : _getCoinsService = getCoinsService,
        _getCoinDataService = getCoinDataService,
        _extractUserIdService = extractUserIdService;

  final String username;
  final GetCoinsService _getCoinsService;
  final GetCoinDataService _getCoinDataService;
  final ExtractUserIdService _extractUserIdService;

  Future<CoinsResponse> getCoins({
    required int currentVersion,
  }) {
    final userId = _extractUserIdService.extractUserId(username: username);
    return _getCoinsService.getCoins(
      username: username,
      userId: userId,
      currentVersion: currentVersion,
    );
  }

  Future<Coin> getCoinData({
    required String contractAddress,
    required String network,
  }) {
    return _getCoinDataService.getCoinData(
      contractAddress: contractAddress,
      network: network,
    );
  }

  Future<List<Coin>> syncCoins(Set<String> symbolGroups) {
    return _getCoinsService.syncCoins(
      username: username,
      symbolGroups: symbolGroups,
    );
  }

  Future<List<Coin>> getCoinsBySymbolGroup(String symbolGroup) {
    final userId = _extractUserIdService.extractUserId(username: username);
    return _getCoinsService.getCoinsBySymbolGroup(
      userId: userId,
      username: username,
      symbolGroup: symbolGroup,
    );
  }

  Future<List<Coin>> searchCoins({
    required String keyword,
    int limit = 10,
    int offset = 0,
  }) {
    return _getCoinsService.searchCoins(
      username: username,
      keyword: keyword,
      limit: limit,
      offset: offset,
    );
  }
}

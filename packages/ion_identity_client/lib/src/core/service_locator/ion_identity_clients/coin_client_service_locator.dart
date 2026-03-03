// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/coins/ion_identity_coins.dart';
import 'package:ion_identity_client/src/coins/services/get_coin_data/data_sources/get_coin_data_data_source.dart';
import 'package:ion_identity_client/src/coins/services/get_coin_data/get_coin_data_service.dart';
import 'package:ion_identity_client/src/coins/services/get_coins/data_sources/get_coins_data_source.dart';
import 'package:ion_identity_client/src/coins/services/get_coins/get_coins_service.dart';
import 'package:ion_identity_client/src/coins/services/search_coins/data_sources/search_coins_data_source.dart';
import 'package:ion_identity_client/src/coins/services/search_coins/search_coins_service.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/auth_client_service_locator.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_service_locator.dart';

class CoinsClientServiceLocator {
  factory CoinsClientServiceLocator() {
    return _instance;
  }

  CoinsClientServiceLocator._internal();

  static final CoinsClientServiceLocator _instance = CoinsClientServiceLocator._internal();

  IONIdentityCoins coins({
    required String username,
    required IONIdentityConfig config,
  }) {
    return IONIdentityCoins(
      username: username,
      getCoinsService: getCoins(username: username, config: config),
      getCoinDataService: getCoinData(username: username, config: config),
      searchCoinsService: searchCoins(config: config),
      extractUserIdService: AuthClientServiceLocator().extractUserId(),
    );
  }

  GetCoinsService getCoins({
    required String username,
    required IONIdentityConfig config,
  }) {
    return GetCoinsService(
      getCoinsDataSource: GetCoinsDataSource(
        networkClient: IONIdentityServiceLocator.networkClient(config: config),
        tokenStorage: IONIdentityServiceLocator.tokenStorage(),
      ),
    );
  }

  SearchCoinsService searchCoins({
    required IONIdentityConfig config,
  }) {
    return SearchCoinsService(
      searchCoinsDataSource: SearchCoinsDataSource(
        networkClient: IONIdentityServiceLocator.networkClient(config: config),
        tokenStorage: IONIdentityServiceLocator.tokenStorage(),
      ),
    );
  }

  GetCoinDataService getCoinData({
    required String username,
    required IONIdentityConfig config,
  }) {
    return GetCoinDataService(
      getCoinDataDataSource: GetCoinDataDataSource(
        username: username,
        networkClient: IONIdentityServiceLocator.networkClient(config: config),
        tokenStorage: IONIdentityServiceLocator.tokenStorage(),
      ),
    );
  }
}

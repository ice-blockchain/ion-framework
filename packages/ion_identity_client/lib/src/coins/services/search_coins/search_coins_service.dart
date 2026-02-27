// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/coins/models/coin.f.dart';
import 'package:ion_identity_client/src/coins/services/search_coins/data_sources/search_coins_data_source.dart';

class SearchCoinsService {
  SearchCoinsService({
    required SearchCoinsDataSource searchCoinsDataSource,
  }) : _searchCoinsDataSource = searchCoinsDataSource;

  final SearchCoinsDataSource _searchCoinsDataSource;

  Future<List<Coin>> searchCoins({
    required String username,
    required String keyword,
    int limit = 10,
    int offset = 0,
  }) {
    return _searchCoinsDataSource.searchCoins(
      username: username,
      keyword: keyword,
      limit: limit,
      offset: offset,
    );
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class SearchCoinsDataSource {
  SearchCoinsDataSource({
    required TokenStorage tokenStorage,
    required NetworkClient networkClient,
  })  : _tokenStorage = tokenStorage,
        _networkClient = networkClient;

  final TokenStorage _tokenStorage;
  final NetworkClient _networkClient;

  String _getToken(String username) {
    final token = _tokenStorage.getToken(username: username)?.token;
    if (token == null) {
      throw const UnauthenticatedException();
    }
    return token;
  }

  Future<List<Coin>> searchCoins({
    required String username,
    required String keyword,
    int limit = 10,
    int offset = 0,
  }) async {
    final token = _getToken(username);

    return _networkClient.get(
      '/v2/coins',
      queryParams: {
        'keyword': keyword,
        'limit': limit,
        'offset': offset,
      },
      headers: RequestHeaders.getTokenHeader(token: token),
      decoder: (result, _) => parseList(result, fromJson: Coin.fromJson),
    );
  }
}

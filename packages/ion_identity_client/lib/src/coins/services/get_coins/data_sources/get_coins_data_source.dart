// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/coins/models/coins_response.f.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class GetCoinsDataSource {
  GetCoinsDataSource({
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

  Future<CoinsResponse> getCoins({
    required String username,
    required String userId,
    required int currentVersion,
  }) async {
    final token = _getToken(username);

    final response = await _networkClient.get(
      '/v1/users/$userId/coins',
      queryParams: {
        'version': currentVersion,
      },
      headers: RequestHeaders.getAuthorizationHeaders(
        token: token,
        username: username,
      ),
      decoder: (response, _) {
        if (response is String && response.isEmpty) {
          return CoinsResponse(coins: [], networks: [], version: currentVersion);
        }

        return parseJsonObject(
          response,
          fromJson: CoinsResponse.fromJson,
        );
      },
    );
    return response;
  }

  Future<List<Coin>> syncCoins({
    required String username,
    required Set<String> symbolGroups,
  }) async {
    final token = _getToken(username);

    return _networkClient.patch(
      '/v1/sync-coins',
      queryParams: {
        'symbolGroup': symbolGroups.toList(),
      },
      headers: RequestHeaders.getTokenHeader(token: token),
      decoder: (result, _) => parseList(result, fromJson: Coin.fromJson),
    );
  }

  Future<List<Coin>> getCoinsBySymbolGroup({
    required String username,
    required String userId,
    required String symbolGroup,
  }) async {
    final token = _getToken(username);

    return _networkClient.get(
      '/v1/users/$userId/coins/$symbolGroup',
      headers: RequestHeaders.getTokenHeader(token: token),
      decoder: (result, _) => parseList(result, fromJson: Coin.fromJson),
    );
  }
}

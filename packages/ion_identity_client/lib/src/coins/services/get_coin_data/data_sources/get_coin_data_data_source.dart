// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class GetCoinDataDataSource {
  GetCoinDataDataSource({
    required String username,
    required TokenStorage tokenStorage,
    required NetworkClient networkClient,
  })  : _username = username,
        _tokenStorage = tokenStorage,
        _networkClient = networkClient;

  final String _username;
  final TokenStorage _tokenStorage;
  final NetworkClient _networkClient;

  Future<Coin> getCoinData({
    required String contractAddress,
    required String network,
  }) async {
    final token = _tokenStorage.getToken(username: _username)?.token;
    if (token == null) {
      throw const UnauthenticatedException();
    }

    final response = await _networkClient.post(
      '/v1/coins',
      headers: RequestHeaders.getTokenHeader(
        token: token,
      ),
      data: {
        'contractAddress': contractAddress,
        'network': network,
      },
      decoder: (response, _) => parseJsonObject(
        response,
        fromJson: Coin.fromJson,
      ),
    );

    return response;
  }
}

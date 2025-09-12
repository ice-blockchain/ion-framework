// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class IONConnectIndexersDataSource {
  IONConnectIndexersDataSource(
    this._networkClient,
    this._tokenStorage,
  );

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  static const basePath = '/v1/users';

  Future<List<String>> fetchIONConnectIndexers({
    required String username,
    required String userId,
  }) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    final response = await _networkClient.get(
      '$basePath/$userId/ion-connect-indexers',
      headers: RequestHeaders.getAuthorizationHeaders(
        username: username,
        token: token.token,
      ),
      decoder: (result, _) =>
          parseJsonObject(result, fromJson: IONConnectIndexersResponse.fromJson),
    );

    return response.ionConnectIndexers;
  }
}

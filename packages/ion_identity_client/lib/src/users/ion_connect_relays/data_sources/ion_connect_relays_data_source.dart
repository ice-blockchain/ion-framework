// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class IONConnectRelaysDataSource {
  IONConnectRelaysDataSource(
    this._networkClient,
    this._tokenStorage,
  );

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  static const basePath = '/v1/users';

  Future<List<IdentityUserInfo>> fetchIONConnectRelays({
    required String username,
    required List<String> masterPubkeys,
  }) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    final response = await _networkClient.get(
      '$basePath/ion-connect-relays',
      queryParams: {
        'masterPubkey': masterPubkeys,
      },
      headers: RequestHeaders.getAuthorizationHeaders(
        username: username,
        token: token.token,
      ),
      decoder: (result, _) => parseList(result, fromJson: IdentityUserInfo.fromJson),
    );

    return response;
  }
}

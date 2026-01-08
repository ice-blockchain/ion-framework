// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class SendDeeplinkDataSource {
  const SendDeeplinkDataSource(
    this._networkClient,
    this._tokenStorage,
  );

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  /// Sends a deeplink to the backend for a given event address
  /// PUT /v1/onlineplus-deeplinks/:eventAddress
  Future<void> sendDeeplink(
    String username, {
    required String eventAddress,
    required String deeplink,
  }) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    await _networkClient.put<void>(
      '/v1/onlineplus-deeplinks/$eventAddress',
      data: {'deeplink': deeplink},
      headers: RequestHeaders.getAuthorizationHeaders(
        token: token.token,
        username: username,
      ),
      decoder: (response, _) {},
    );
  }
}

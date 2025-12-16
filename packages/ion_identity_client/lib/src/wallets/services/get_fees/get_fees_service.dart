// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class GetFeesService {
  const GetFeesService({
    required NetworkClient networkClient,
    required TokenStorage tokenStorage,
    required this.username,
  })  : _tokenStorage = tokenStorage,
        _networkClient = networkClient;

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;
  final String username;

  Future<Map<String, dynamic>> getFees(List<String> networks) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    final headers = {
      ...RequestHeaders.getAuthorizationHeaders(
        token: token.token,
        username: username,
      ),
    };
    final result = await _networkClient.get(
      '/networks/fees',
      headers: headers,
      queryParams: {
        'network': networks.join(','),
      },
      decoder: (response, _) => response,
    );

    return result as Map<String, dynamic>;
  }
}

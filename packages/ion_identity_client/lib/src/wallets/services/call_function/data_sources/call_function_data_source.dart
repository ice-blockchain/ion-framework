// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';
import 'package:sprintf/sprintf.dart';

class CallFunctionDataSource {
  const CallFunctionDataSource({
    required NetworkClient networkClient,
    required TokenStorage tokenStorage,
    required this.username,
  })  : _networkClient = networkClient,
        _tokenStorage = tokenStorage;

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;
  final String username;

  /// [network]
  static const _callFunctionPath = '/networks/%s/call-function';

  Future<dynamic> callFunction({
    required String network,
    required CallFunctionRequest request,
  }) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    final headers = RequestHeaders.getAuthorizationHeaders(
      token: token.token,
      username: username,
    );

    return _networkClient.post(
      sprintf(_callFunctionPath, [network]),
      data: request.toJson(),
      headers: headers,
      decoder: (response, _) => response,
    );
  }
}

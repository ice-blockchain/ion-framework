// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class HashtagsDataSource {
  HashtagsDataSource({
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

  Future<List<String>> getHashtags({
    required String username,
    required String query,
    required int limit,
  }) async {
    final token = _getToken(username);

    final response = await _networkClient.get(
      '/v1/statistics/hashtags',
      queryParams: {
        'keyword': query,
        'limit': limit,
      },
      headers: RequestHeaders.getAuthorizationHeaders(
        token: token,
        username: username,
      ),
      decoder: (response, _) {
        if (response is! List || response.isEmpty) {
          return <String>[];
        }

        return response.cast<String>();
      },
    );
    return response;
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class UserDetailsDataSource {
  UserDetailsDataSource(
    this._networkClient,
    this._tokenStorage,
  );

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  static const usersDetailsPath = '/auth/users';

  Future<UserDetails> fetchDetails({
    required String username,
    required String userId,
  }) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    final response = await _networkClient.get(
      '$usersDetailsPath/$userId',
      headers: RequestHeaders.getAuthorizationHeaders(
        token: token.token,
        username: username,
      ),
      decoder: (result, _) => parseJsonObject(result, fromJson: UserDetails.fromJson),
    );

    return response;
  }
}

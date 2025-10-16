// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';
import 'package:ion_identity_client/src/users/get_content_creators/models/get_content_creators_request.f.dart';
import 'package:ion_identity_client/src/users/models/identity_user_info.f.dart';

class IONContentCreatorsDataSource {
  IONContentCreatorsDataSource(
    this._networkClient,
    this._tokenStorage,
  );

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  static const basePath = '/v1/users';

  Future<List<IdentityUserInfo>> fetchIONContentCreators({
    required int limit,
    required String username,
    required List<String> excludeMasterPubKeys,
  }) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    final response = await _networkClient.post(
      '$basePath/get-content-creators',
      queryParams: {'limit': limit},
      data: GetContentCreatorsRequest(excludeMasterPubKeys: excludeMasterPubKeys).toJson(),
      headers: RequestHeaders.getAuthorizationHeaders(
        username: username,
        token: token.token,
      ),
      decoder: (result, _) => (result as List<dynamic>)
          .map((e) => IdentityUserInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    return response;
  }
}

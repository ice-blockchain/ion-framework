// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';
import 'package:ion_identity_client/src/users/models/identity_user_info.f.dart';

class SearchUsersSocialProfileDataSource {
  SearchUsersSocialProfileDataSource(
    this._networkClient,
    this._tokenStorage,
  );

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  static const basePath = '/v1';

  Future<List<IdentityUserInfo>> searchForUsersByKeyword({
    required String keyword,
    required SearchUsersSocialProfileType searchType,
    required int limit,
    required int offset,
    required String username,
    String? followedBy,
    String? followerOf,
  }) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    final response = await _networkClient.get(
      '$basePath/user-social-profiles',
      queryParams: {
        'limit': limit,
        'keyword': keyword,
        'offset': offset,
        'type': searchType.name,
        if (followedBy != null) 'followedBy': followedBy,
        if (followerOf != null) 'followerOf': followerOf,
      },
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

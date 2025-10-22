// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class GetUserSocialProfileDataSource {
  GetUserSocialProfileDataSource(
    this._networkClient,
    this._tokenStorage,
  );

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  static const basePath = '/v1/users';

  Future<UserSocialProfileData> getUserSocialProfile({
    required String username,
    required String userIdOrMasterKey,
  }) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    try {
      return await _networkClient.get(
        '$basePath/$userIdOrMasterKey/profiles/social',
        headers: RequestHeaders.getAuthorizationHeaders(
          username: username,
          token: token.token,
        ),
        decoder: (result, _) => parseJsonObject(result, fromJson: UserSocialProfileData.fromJson),
      );
    } on RequestExecutionException catch (e) {
      final exception = _mapException(e);
      throw exception;
    }
  }

  Exception _mapException(RequestExecutionException e) {
    if (e.error is! DioException) return e;
    final exception = e.error as DioException;

    if (exception.response?.statusCode == 404) {
      return const UserNotFoundException();
    }

    return e;
  }
}

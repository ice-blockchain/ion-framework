// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class NicknameAvailabilityDataSource {
  NicknameAvailabilityDataSource(
    this._networkClient,
    this._tokenStorage,
  );

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  static const basePath = '/v1/users';

  Future<void> verifyNicknameAvailability({
    required String username,
    required String nickname,
  }) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }
    try {
      await _networkClient.get(
        '$basePath/verify-username-availability',
        queryParams: {'username': nickname},
        headers: RequestHeaders.getAuthorizationHeaders(
          username: username,
          token: token.token,
        ),
        decoder: (json, _) => json,
      );
    } on RequestExecutionException catch (e) {
      final exception = _mapException(e);
      throw exception;
    }
  }

  Exception _mapException(RequestExecutionException e) {
    if (e.error is! DioException) return e;

    final exception = e.error as DioException;
    if (InvalidNicknameException.isMatch(exception)) {
      return InvalidNicknameException();
    }
    if (NicknameAlreadyExistsException.isMatch(exception)) {
      return NicknameAlreadyExistsException();
    }

    return e;
  }
}

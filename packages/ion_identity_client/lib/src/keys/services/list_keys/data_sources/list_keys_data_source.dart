// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class ListKeysDataSource {
  const ListKeysDataSource(
    this.username,
    this._networkClient,
    this._tokenStorage,
  );

  final String username;
  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  static const keysPath = '/keys';

  Future<ListKeysResponse> listKeys({
    String? owner,
    int? limit,
    String? paginationToken,
  }) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    try {
      return await _networkClient.get(
        keysPath,
        headers: RequestHeaders.getAuthorizationHeaders(
          token: token.token,
          username: username,
        ),
        queryParams: {
          if (owner != null) 'owner': owner,
          if (limit != null) 'limit': limit,
          if (paginationToken != null) 'paginationToken': paginationToken,
        },
        decoder: (result, _) => parseJsonObject(result, fromJson: ListKeysResponse.fromJson),
      );
    } on NetworkException catch (e) {
      if (e is RequestExecutionException && e.error is DioException) {
        final dioError = e.error as DioException;
        if (dioError.response?.statusCode == 401) {
          throw const UnauthenticatedException();
        }
      }
      throw const UnknownIONIdentityException();
    }
  }
}

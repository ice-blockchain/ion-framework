// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class GetEstimateFeesDataSource {
  const GetEstimateFeesDataSource(this._networkClient, this._tokenStorage);

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  Future<EstimateFee> getEstimateFees(String username, String network) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    try {
      return _networkClient.get(
        '/networks/fees',
        headers: RequestHeaders.getTokenHeader(token: token.token),
        queryParams: {
          'network': network,
        },
        decoder: (json, _) => parseJsonObject(json, fromJson: EstimateFee.fromJson),
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

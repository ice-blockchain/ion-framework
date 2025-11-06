// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';
import 'package:ion_identity_client/src/wallets/exceptions/wallets_exceptions.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_history/models/get_wallet_history_request_params.f.dart';
import 'package:sprintf/sprintf.dart';

class GetWalletHistoryDataSource {
  const GetWalletHistoryDataSource(
    this._networkClient,
    this._tokenStorage,
  );

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  static const walletHistoryPath = '/wallets/%s/history';

  Future<WalletHistory> getWalletHistory(
    String username,
    String walletId, {
    String? pageToken,
    int? pageSize,
  }) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    try {
      return await _networkClient.get(
        sprintf(walletHistoryPath, [walletId]),
        headers: RequestHeaders.getAuthorizationHeaders(
          token: token.token,
          username: username,
        ),
        queryParams: GetWalletHistoryRequestParams(
          limit: pageSize,
          paginationToken: pageToken,
        ).toJson(),
        decoder: (result, _) => parseJsonObject(result, fromJson: WalletHistory.fromJson),
      );
    } on NetworkException catch (e) {
      if (e is RequestExecutionException && e.error is DioException) {
        final dioError = e.error as DioException;
        if (dioError.response?.statusCode == 401) {
          throw const UnauthenticatedException();
        }
        if (dioError.response?.statusCode == 404) {
          throw const WalletNotFoundException();
        }
      }
      if (e is DecodeException) {
        throw FailedToParseResponseException(e.message);
      }
      throw const UnknownIONIdentityException();
    }
  }
}

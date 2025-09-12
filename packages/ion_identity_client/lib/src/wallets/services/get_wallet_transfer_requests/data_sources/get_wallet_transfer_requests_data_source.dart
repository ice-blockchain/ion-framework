// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';
import 'package:ion_identity_client/src/wallets/exceptions/wallets_exceptions.dart';
import 'package:sprintf/sprintf.dart';

class GetWalletTransferRequestsDataSource {
  const GetWalletTransferRequestsDataSource(
    this._networkClient,
    this._tokenStorage,
  );

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  static const walletTransfersPath = '/wallets/%s/transfers';

  UserToken _token(String username) {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }
    return token;
  }

  IONIdentityException _handleNetworkException(NetworkException e) {
    if (e is RequestExecutionException && e.error is DioException) {
      final dioError = e.error as DioException;
      if (dioError.response?.statusCode == 401) {
        throw const UnauthenticatedException();
      }
      if (dioError.response?.statusCode == 404) {
        throw const WalletNotFoundException();
      }
    }
    throw const UnknownIONIdentityException();
  }

  Future<WalletTransferRequests> getWalletTransferRequests(
    String username,
    String walletId, {
    String? pageToken,
    int? pageSize,
  }) async {
    final token = _token(username);

    try {
      return await _networkClient.get(
        sprintf(walletTransfersPath, [walletId]),
        headers: RequestHeaders.getAuthorizationHeaders(
          token: token.token,
          username: username,
        ),
        queryParams: {
          if (pageToken != null) 'paginationToken': pageToken,
          if (pageSize != null) 'limit': pageSize,
        },
        decoder: (result, _) => parseJsonObject(result, fromJson: WalletTransferRequests.fromJson),
      );
    } on NetworkException catch (e) {
      throw _handleNetworkException(e);
    }
  }

  Future<WalletTransferRequest> getWalletTransferRequestById(
    String username, {
    required String walletId,
    required String transferId,
  }) async {
    final token = _token(username);

    try {
      return await _networkClient.get(
        '/wallets/$walletId/transfers/$transferId',
        headers: RequestHeaders.getAuthorizationHeaders(
          token: token.token,
          username: username,
        ),
        decoder: (result, _) => parseJsonObject(result, fromJson: WalletTransferRequest.fromJson),
      );
    } on NetworkException catch (e) {
      throw _handleNetworkException(e);
    }
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';
import 'package:sprintf/sprintf.dart';

class WalletViewsDataSource {
  const WalletViewsDataSource(
    this._networkClient,
    this._tokenStorage,
  );

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  static const _basePath = '/v1/users/%s/wallet-views';
  static const _specificViewPath = '/v1/users/%s/wallet-views/%s';

  /// Header used by backend to return pagination token for next page
  static const String _nextPageHeader = 'x-next-page';

  UserToken _token(String username) {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }
    return token;
  }

  Future<List<ShortWalletView>> getWalletViews(
    String username,
    String userId,
  ) async {
    final token = _token(username);

    return _networkClient.get(
      sprintf(_basePath, [userId]),
      headers: RequestHeaders.getAuthorizationHeaders(
        token: token.token,
        username: username,
      ),
      decoder: (json, _) => parseList(json, fromJson: ShortWalletView.fromJson),
    );
  }

  Future<WalletView> createWalletView(
    String userId,
    String username,
    CreateUpdateWalletViewRequest request,
  ) {
    final token = _token(username);

    return _networkClient.post(
      sprintf(_basePath, [userId]),
      headers: RequestHeaders.getTokenHeader(
        token: token.token,
      ),
      data: request.toJson(),
      decoder: (json, _) => parseJsonObject(json, fromJson: WalletView.fromJson),
    );
  }

  /// Returns wallet view data with optional NFTs pagination support.
  /// When [limit] is provided, the server will limit the number of NFTs and
  /// may return the next page token in the [_nextPageHeader] header.
  Future<WalletViewResponse> getWalletView({
    required String userId,
    required String username,
    required String walletViewId,
    int? limit,
    String? paginationToken,
  }) async {
    final token = _token(username);

    return _networkClient.get(
      sprintf(_specificViewPath, [userId, walletViewId]),
      headers: RequestHeaders.getAuthorizationHeaders(
        token: token.token,
        username: username,
      ),
      queryParams: {
        if (limit != null) 'limit': limit,
        if (paginationToken != null) 'paginationToken': paginationToken,
      },
      decoder: (json, headers) => (
        walletView: parseJsonObject(json, fromJson: WalletView.fromJson),
        nextPageToken: headers[_nextPageHeader]?.firstOrNull,
      ),
    );
  }

  Future<WalletView> updateWalletView({
    required String userId,
    required String username,
    required String walletViewId,
    required CreateUpdateWalletViewRequest request,
  }) {
    final token = _token(username);

    return _networkClient.put(
      sprintf(_specificViewPath, [userId, walletViewId]),
      headers: RequestHeaders.getAuthorizationHeaders(
        token: token.token,
        username: username,
      ),
      data: request.toJson(),
      decoder: (json, _) => parseJsonObject(json, fromJson: WalletView.fromJson),
    );
  }

  Future<void> deleteWalletView(
    String username,
    String userId,
    String walletViewId,
  ) async {
    final token = _token(username);

    await _networkClient.delete(
      sprintf(_specificViewPath, [userId, walletViewId]),
      headers: RequestHeaders.getTokenHeader(token: token.token),
      decoder: (json, _) => null,
    );
  }
}

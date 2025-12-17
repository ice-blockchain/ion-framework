// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/delegated_login/data_sources/delegated_login_data_source.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';

class DelegatedLoginService {
  const DelegatedLoginService({
    required this.dataSource,
    required this.tokenStorage,
  });

  final DelegatedLoginDataSource dataSource;
  final TokenStorage tokenStorage;

  Future<UserToken> delegatedLogin({
    required String username,
  }) async {
    try {
      final tokenResponse = await dataSource.delegatedLogin(username: username);
      await tokenStorage.setToken(username: username, newToken: tokenResponse.token);

      final userToken = tokenStorage.getToken(username: username);
      if (userToken == null) {
        throw const UnauthenticatedException();
      }
      return userToken;
    } catch (e) {
      await tokenStorage.removeToken(username: username);
      rethrow;
    }
  }
}

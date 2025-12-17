// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/logout/data_sources/logout_data_source.dart';
import 'package:ion_identity_client/src/core/storage/private_key_storage.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';

class LogoutService {
  const LogoutService({
    required this.username,
    required this.dataSource,
    required this.tokenStorage,
    required this.privateKeyStorage,
  });

  final String username;
  final LogoutDataSource dataSource;
  final TokenStorage tokenStorage;
  final PrivateKeyStorage privateKeyStorage;

  Future<void> logOut() async {
    final token = tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }
    try {
      await dataSource.logOut(username: username, token: token.token);
    } finally {
      await tokenStorage.removeToken(username: username);
    }
  }
}

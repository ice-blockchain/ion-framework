// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class GetCredentialsDataSource {
  GetCredentialsDataSource({
    required this.networkClient,
    required this.tokenStorage,
  });

  static const createCredentialPath = '/auth/credentials';

  final NetworkClient networkClient;
  final TokenStorage tokenStorage;

  Future<List<Credential>> getCredentialsList({
    required String username,
  }) {
    final token = tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    return networkClient.get(
      createCredentialPath,
      decoder: (result, _) {
        if (result case {'items': final List<dynamic> items}) {
          return parseList(items, fromJson: Credential.fromJson);
        }
        return [];
      },
      headers: RequestHeaders.getAuthorizationHeaders(
        token: token.token,
        username: username,
      ),
    );
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/http_method.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';
import 'package:ion_identity_client/src/signer/types/user_action_signing_request.dart';

const recoveryKeyBody = {'kind': 'RecoveryKey'};

class CreateRecoveryCredentialsDataSource {
  CreateRecoveryCredentialsDataSource({
    required this.networkClient,
    required this.tokenStorage,
  });

  static const createCredentialInitPath = '/auth/credentials/init';
  static const createCredentialPath = '/auth/credentials';

  final NetworkClient networkClient;
  final TokenStorage tokenStorage;

  Future<CreateCredentialsResponse> createCredentialInit({
    required String username,
  }) {
    final token = tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    return networkClient.post(
      createCredentialInitPath,
      data: recoveryKeyBody,
      decoder: (result, _) => parseJsonObject(result, fromJson: CreateCredentialsResponse.fromJson),
      headers: RequestHeaders.getAuthorizationHeaders(
        token: token.token,
        username: username,
      ),
    );
  }

  UserActionSigningRequest buildCreateCredentialSigningRequest(
    String username,
    CredentialRequestData credentialRequestData,
  ) {
    return UserActionSigningRequest(
      username: username,
      method: HttpMethod.post,
      path: createCredentialPath,
      body: credentialRequestData.toJson(),
    );
  }
}

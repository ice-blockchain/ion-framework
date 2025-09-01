// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/register/data_sources/register_data_source.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';

class RegisterService {
  RegisterService({
    required this.username,
    required this.dataSource,
    required this.identitySigner,
    required this.tokenStorage,
  });

  final String username;
  final RegisterDataSource dataSource;
  final IdentitySigner identitySigner;
  final TokenStorage tokenStorage;

  Future<void> verifyEmailEarlyAccess({
    required String email,
  }) async {
    return dataSource.verifyEmailEarlyAccess(email: email);
  }

  /// Registers a new user using the provided username and handles the necessary
  /// cryptographic operations and API interactions.
  ///
  /// This method performs the following steps:
  /// 1. Checks if the device can authenticate using passkeys.
  /// 2. Initiates the registration process with the server.
  /// 3. Generates new credentials info.
  /// 4. Completes the registration with the server.
  /// 5. Stores the received authentication tokens.
  ///
  /// Throws:
  /// - [PasskeyNotAvailableException] if the device cannot authenticate using passkeys.
  /// - Other exceptions may be thrown during API interactions or token storage.
  Future<void> registerUser(GetRequestId getRequestId, String? earlyAccessEmail) async {
    final passkeyAuthAvailable = await identitySigner.isPasskeyAvailable();
    if (!passkeyAuthAvailable) {
      throw const PasskeyNotAvailableException();
    }
    await _completeRegistration(
      identitySigner.registerWithPasskey,
      getRequestId,
      earlyAccessEmail,
    );
  }

  /// Registers a new user using the provided username and handles the necessary
  /// cryptographic operations and API interactions.
  ///
  /// This method performs the following steps:
  /// 1. Checks if the device can authenticate using passkeys.
  /// 2. Initiates the registration process with the server.
  /// 3. Generates new credentials info.
  /// 4. Completes the registration with the server.
  /// 5. Stores the received authentication tokens.
  Future<void> registerWithPassword(
    String password,
    GetRequestId getRequestId,
    String? earlyAccessEmail,
  ) async {
    await _completeRegistration(
      (challenge) => identitySigner.registerWithPassword(
        challenge: challenge.challenge,
        password: password,
        username: username,
        credentialKind: CredentialKind.PasswordProtectedKey,
      ),
      getRequestId,
      earlyAccessEmail,
    );
  }

  Future<void> _completeRegistration(
    Future<CredentialRequestData> Function(UserRegistrationChallenge) getCredentials,
    GetRequestId getRequestId,
    String? earlyAccessEmail,
  ) async {
    final userRegistrationChallenge =
        await dataSource.registerInit(username: username, earlyAccessEmail: earlyAccessEmail);
    final credentialData = await getCredentials(userRegistrationChallenge);

    final requestId = await getRequestId(username);
    final registrationCompleteResponse = await dataSource.registerComplete(
      credentialData: credentialData,
      temporaryAuthenticationToken: userRegistrationChallenge.temporaryAuthenticationToken!,
      earlyAccessEmail: earlyAccessEmail,
      requestId: requestId,
    );
    await tokenStorage.setTokens(
      username: username,
      newTokens: registrationCompleteResponse.authentication,
    );
  }
}

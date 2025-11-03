// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/dtos/private_key_data.j.dart';
import 'package:ion_identity_client/src/auth/helpers/extract_username_from_token_helper.dart';
import 'package:ion_identity_client/src/auth/services/login/data_sources/login_data_source.dart';
import 'package:ion_identity_client/src/auth/services/login/login_capabilities.dart';
import 'package:ion_identity_client/src/auth/services/login/login_executors.dart';
import 'package:ion_identity_client/src/core/storage/biometrics_state_storage.dart';
import 'package:ion_identity_client/src/core/storage/private_key_storage.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/signer/dtos/dtos.dart';

class LoginService {
  const LoginService({
    required this.username,
    required this.dataSource,
    required this.tokenStorage,
    required this.privateKeyStorage,
    required this.biometricsStateStorage,
    required this.loginExecutorFactory,
  });

  final String username;
  final LoginDataSource dataSource;
  final TokenStorage tokenStorage;
  final PrivateKeyStorage privateKeyStorage;
  final BiometricsStateStorage biometricsStateStorage;
  final LoginExecutorFactory loginExecutorFactory;

  /// Initializes the login process for the specified [username].
  ///
  /// 1. Invokes loginInit to retrieve the [UserActionChallenge] data.
  /// 2. Checks whether the challenge's [UserActionChallenge.supportedCredentialKinds] contains [CredentialKind.Fido2].
  ///    - If **Fido2** is not supported, passkey authentication is not available for the account.
  ///    - In this case, checks if the user is a password-based user by examining the `passwordProtectedKey` field.
  ///    - If an encrypted private key exists, it is securely stored.
  ///
  /// This flow ensures that if **Fido2**-based authentication is not available,
  /// a password-based credential (if present) is captured and stored appropriately.
  Future<void> verifyUserLoginFlow() async {
    try {
      final challenge = await dataSource.loginInit(username: username);
      if (challenge.supportedCredentialKinds
              .any((SupportedCredentialKinds2 credKind) => credKind.kind == CredentialKind.Fido2) ==
          false) {
        final credentialDescriptor = challenge.allowCredentials.passwordProtectedKey?.firstOrNull;
        final encryptedPrivateKey = credentialDescriptor?.encryptedPrivateKey;
        if (encryptedPrivateKey != null &&
            privateKeyStorage.getPrivateKey(username: username) == null) {
          await privateKeyStorage.setPrivateKey(
            username: username,
            privateKeyData: PrivateKeyData(),
          );
        }
      }
    } on RequestExecutionException catch (e) {
      final dioException = e.error is DioException ? e.error as DioException : null;
      if (dioException?.response?.statusCode == 401 &&
          dioException?.response?.data['error']['message'] == 'Unauthorized') {
        throw const IdentityNotFoundIONIdentityException();
      }
      if (dioException?.response?.statusCode == 403 &&
          dioException?.response?.data['error']['message'] == '2FA_REQUIRED') {
        final twoFAOptionsCount = dioException?.response?.data['data']['n'] as int;
        if (privateKeyStorage.getPrivateKey(username: username) == null) {
          await privateKeyStorage.setPrivateKey(
            username: username,
            privateKeyData: PrivateKeyData(),
          );
        }
        throw TwoFARequiredException(twoFAOptionsCount);
      }
      rethrow;
    }
  }

  Future<LoginCapabilities> getLoginCapabilities() async {
    try {
      final challenge = await dataSource.loginInit(username: username);

      final supportsPasskey = challenge.supportedCredentialKinds
          .any((SupportedCredentialKinds2 credKind) => credKind.kind == CredentialKind.Fido2);

      final credentialDescriptor = challenge.allowCredentials.passwordProtectedKey?.firstOrNull;
      final encryptedPrivateKey = credentialDescriptor?.encryptedPrivateKey;
      final passwordFlowAvailable = encryptedPrivateKey != null;

      if (!supportsPasskey &&
          passwordFlowAvailable &&
          privateKeyStorage.getPrivateKey(username: username) == null) {
        await privateKeyStorage.setPrivateKey(
          username: username,
          privateKeyData: PrivateKeyData(),
        );
      }

      return LoginCapabilities(
        supportsPasskey: supportsPasskey,
        passwordFlowAvailable: passwordFlowAvailable,
        identityFound: true,
      );
    } on RequestExecutionException catch (e) {
      final dioException = e.error is DioException ? e.error as DioException : null;
      if (dioException?.response?.statusCode == 401 &&
          dioException?.response?.data['error']['message'] == 'Unauthorized') {
        return const LoginCapabilities(
          supportsPasskey: false,
          passwordFlowAvailable: false,
          identityFound: false,
        );
      }
      if (dioException?.response?.statusCode == 403 &&
          dioException?.response?.data['error']['message'] == '2FA_REQUIRED') {
        final twoFAOptionsCount = dioException?.response?.data['data']['n'] as int;
        if (privateKeyStorage.getPrivateKey(username: username) == null) {
          await privateKeyStorage.setPrivateKey(
            username: username,
            privateKeyData: PrivateKeyData(),
          );
        }
        return LoginCapabilities(
          supportsPasskey: false,
          passwordFlowAvailable: true,
          identityFound: true,
          twoFAOptionsCount: twoFAOptionsCount,
        );
      }
      rethrow;
    }
  }

  /// Logs in an existing user using the provided username, handling the necessary
  /// API interactions and storing the authentication token securely.
  ///
  /// This method performs the following steps:
  /// 1. Checks if the device can authenticate using passkeys.
  /// 2. Initiates the login process with the server.
  /// 3. Generates a passkey assertion.
  /// 4. Completes the login with the server.
  /// 5. Stores the received authentication tokens.
  ///
  /// Throws:
  /// - [PasskeyNotAvailableException] if the device cannot authenticate using passkeys.
  /// - [UnauthenticatedException] if the login credentials are invalid.
  /// - [UserDeactivatedException] if the user account has been deactivated.
  /// - [UserNotFoundException] if the user account does not exist.
  /// - [PasskeyValidationException] if the passkey validation fails.
  /// - [UnknownIONIdentityException] for any other unexpected errors during the login process.
  Future<void> login({
    required AuthConfig config,
    required List<TwoFAType> twoFATypes,
    required bool localCredsOnly,
  }) async {
    final challenge = await dataSource.loginInit(username: username, twoFATypes: twoFATypes);

    final executor = loginExecutorFactory.create(
      config: config,
      challenge: challenge,
      username: username,
      localCredsOnly: localCredsOnly,
    );
    final assertion = await executor.execute(
      username: username,
      challenge: challenge,
      localCredsOnly: localCredsOnly,
    );

    final tokens = await dataSource.loginComplete(
      challengeIdentifier: challenge.challengeIdentifier,
      assertion: assertion,
    );

    final tokenKeyUsername = username.isEmpty ? extractUsernameFromToken(tokens.token) : username;
    await tokenStorage.setTokens(
      username: tokenKeyUsername,
      newTokens: tokens,
    );
  }
}

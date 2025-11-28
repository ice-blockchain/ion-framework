// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/helpers/extract_username_from_token_helper.dart';
import 'package:ion_identity_client/src/auth/services/login/data_sources/login_data_source.dart';
import 'package:ion_identity_client/src/auth/services/login/login_executors/login_executor_factory.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';

class LoginUserService {
  const LoginUserService({
    required this.username,
    required this.dataSource,
    required this.tokenStorage,
    required this.loginExecutorFactory,
  });

  final String username;
  final LoginDataSource dataSource;
  final TokenStorage tokenStorage;
  final LoginExecutorFactory loginExecutorFactory;

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
    Future<void>? cancel,
  }) async {
    final challenge = await dataSource.loginInit(username: username, twoFATypes: twoFATypes);

    final executor = loginExecutorFactory.create(
      config: config,
      challenge: challenge,
      username: username,
      localCredsOnly: localCredsOnly,
    );

    final authFuture = executor.execute(
      username: username,
      challenge: challenge,
      localCredsOnly: localCredsOnly,
    );
    final assertion = cancel == null
        ? await authFuture
        : await Future.any<AssertionRequestData>([
            authFuture,
            cancel.then<AssertionRequestData>(
              (_) => throw const SignInCancelException(),
            ),
          ]);

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

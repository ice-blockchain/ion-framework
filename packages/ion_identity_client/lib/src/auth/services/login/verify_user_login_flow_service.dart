// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/dtos/private_key_data.j.dart';
import 'package:ion_identity_client/src/auth/services/login/data_sources/login_data_source.dart';
import 'package:ion_identity_client/src/core/storage/private_key_storage.dart';

class VerifyUserLoginFlowService {
  const VerifyUserLoginFlowService({
    required this.username,
    required this.dataSource,
    required this.privateKeyStorage,
  });

  final String username;
  final LoginDataSource dataSource;
  final PrivateKeyStorage privateKeyStorage;

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
              .any((credKind) => credKind.kind == CredentialKind.Fido2) ==
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
}

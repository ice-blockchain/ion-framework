// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/dtos/private_key_data.j.dart';
import 'package:ion_identity_client/src/auth/services/login/data_sources/login_data_source.dart';
import 'package:ion_identity_client/src/auth/services/login/login_capabilities.dart';
import 'package:ion_identity_client/src/core/storage/private_key_storage.dart';

class GetLoginCapabilitiesService {
  const GetLoginCapabilitiesService({
    required this.username,
    required this.dataSource,
    required this.privateKeyStorage,
  });

  final String username;
  final LoginDataSource dataSource;
  final PrivateKeyStorage privateKeyStorage;

  Future<LoginCapabilities> getLoginCapabilities() async {
    try {
      final challenge = await dataSource.loginInit(username: username);

      final supportsPasskey = challenge.supportedCredentialKinds
          .any((credKind) => credKind.kind == CredentialKind.Fido2);

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
}

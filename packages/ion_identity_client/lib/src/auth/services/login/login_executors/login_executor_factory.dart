// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/login/login_executors/biometrics_login_executor.dart';
import 'package:ion_identity_client/src/auth/services/login/login_executors/login_executor.dart';
import 'package:ion_identity_client/src/auth/services/login/login_executors/passkey_login_executor.dart';
import 'package:ion_identity_client/src/auth/services/login/login_executors/password_login_executor.dart';
import 'package:ion_identity_client/src/core/storage/biometrics_state_storage.dart';
import 'package:ion_identity_client/src/core/storage/private_key_storage.dart';
import 'package:ion_identity_client/src/signer/dtos/user_action_challenge.j.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';

class LoginExecutorFactory {
  const LoginExecutorFactory({
    required this.identitySigner,
    required this.biometricsStateStorage,
    required this.privateKeyStorage,
  });

  final IdentitySigner identitySigner;
  final BiometricsStateStorage biometricsStateStorage;
  final PrivateKeyStorage privateKeyStorage;

  LoginExecutor create({
    required AuthConfig config,
    required UserActionChallenge challenge,
    required String username,
  }) {
    final supportsPasskey = challenge.supportedCredentialKinds.any(
      (credKind) => credKind.kind == CredentialKind.Fido2,
    );
    if (username.isEmpty || supportsPasskey) {
      return PasskeyLoginExecutor(identitySigner: identitySigner);
    }

    final isPasswordUser = privateKeyStorage.getPrivateKey(username: username) != null;
    final biometricsState = biometricsStateStorage.getBiometricsState(username: username);

    final canUseBiometrics = biometricsState == BiometricsState.enabled &&
        config.localisedReasonForBiometrics != null &&
        config.localisedCancelForBiometrics != null;

    if (isPasswordUser && canUseBiometrics) {
      return BiometricsLoginExecutor(
        identitySigner: identitySigner,
        localisedReason: config.localisedReasonForBiometrics!,
        localisedCancel: config.localisedCancelForBiometrics!,
      );
    }

    if (config.getPassword != null) {
      return PasswordLoginExecutor(
        identitySigner: identitySigner,
        getPassword: config.getPassword!,
        biometricsStateStorage: biometricsStateStorage,
      );
    }

    throw const PasskeyNotAvailableException();
  }
}

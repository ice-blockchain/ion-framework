// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/storage/biometrics_state_storage.dart';
import 'package:ion_identity_client/src/core/storage/private_key_storage.dart';
import 'package:ion_identity_client/src/signer/dtos/user_action_challenge.j.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';

abstract class LoginExecutor {
  Future<AssertionRequestData> execute({
    required String username,
    required UserActionChallenge challenge,
    required bool localCredsOnly,
  });
}

class PasskeyLoginExecutor implements LoginExecutor {
  const PasskeyLoginExecutor({required this.identitySigner});

  final IdentitySigner identitySigner;

  @override
  Future<AssertionRequestData> execute({
    required String username,
    required UserActionChallenge challenge,
    required bool localCredsOnly,
  }) {
    return identitySigner.loginWithPasskey(
      username: username,
      challenge: challenge,
      localCredsOnly: localCredsOnly,
    );
  }
}

class BiometricsLoginExecutor implements LoginExecutor {
  const BiometricsLoginExecutor({
    required this.identitySigner,
    required this.localisedReason,
    required this.localisedCancel,
  });

  final IdentitySigner identitySigner;
  final String localisedReason;
  final String localisedCancel;

  @override
  Future<AssertionRequestData> execute({
    required String username,
    required UserActionChallenge challenge,
    required bool localCredsOnly,
  }) async {
    final descriptor = identitySigner.extractPasswordProtectedCredentials(challenge);
    return identitySigner.signWithBiometrics(
      challenge: challenge.challenge,
      username: username,
      encryptedPrivateKey: descriptor.encryptedPrivateKey!,
      credentialId: descriptor.id,
      credentialKind: CredentialKind.PasswordProtectedKey,
      localisedReason: localisedReason,
      localisedCancel: localisedCancel,
    );
  }
}

class PasswordLoginExecutor implements LoginExecutor {
  const PasswordLoginExecutor({
    required this.identitySigner,
    required this.getPassword,
    required this.biometricsStateStorage,
  });

  final IdentitySigner identitySigner;
  final GetPasswordCallback getPassword;
  final BiometricsStateStorage biometricsStateStorage;

  @override
  Future<AssertionRequestData> execute({
    required String username,
    required UserActionChallenge challenge,
    required bool localCredsOnly,
  }) async {
    final descriptor = identitySigner.extractPasswordProtectedCredentials(challenge);
    final assertion = await identitySigner.signWithPassword(
      challenge: challenge.challenge,
      encryptedPrivateKey: descriptor.encryptedPrivateKey!,
      credentialId: descriptor.id,
      credentialKind: CredentialKind.PasswordProtectedKey,
      password: await getPassword(),
    );

    final biometricsState = biometricsStateStorage.getBiometricsState(username: username);
    if (biometricsState == null || biometricsState == BiometricsState.failed) {
      await biometricsStateStorage.updateBiometricsState(
        username: username,
        biometricsState: BiometricsState.canSuggest,
      );
    }
    return assertion;
  }
}

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
    required LoginAuthConfig config,
    required UserActionChallenge challenge,
    required String username,
    required bool localCredsOnly,
  }) {
    if (username.isEmpty) {
      return PasskeyLoginExecutor(identitySigner: identitySigner);
    }

    final supportsPasskey = challenge.supportedCredentialKinds.any(
      (credKind) => credKind.kind == CredentialKind.Fido2,
    );

    if (supportsPasskey && localCredsOnly) {
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

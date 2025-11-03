// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/login/login_executors/login_executor.dart';
import 'package:ion_identity_client/src/core/storage/biometrics_state_storage.dart';
import 'package:ion_identity_client/src/signer/dtos/user_action_challenge.j.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';

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

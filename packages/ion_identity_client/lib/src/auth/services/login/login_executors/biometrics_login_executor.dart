// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/login/login_executors/login_executor.dart';
import 'package:ion_identity_client/src/signer/dtos/user_action_challenge.j.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';

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

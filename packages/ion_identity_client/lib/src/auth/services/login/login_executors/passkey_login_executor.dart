// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/login/login_executors/login_executor.dart';
import 'package:ion_identity_client/src/signer/dtos/user_action_challenge.j.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';

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

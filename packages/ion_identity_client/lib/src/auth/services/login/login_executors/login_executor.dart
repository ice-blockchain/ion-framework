// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/signer/dtos/user_action_challenge.j.dart';

abstract class LoginExecutor {
  Future<AssertionRequestData> execute({
    required String username,
    required UserActionChallenge challenge,
    required bool localCredsOnly,
  });
}

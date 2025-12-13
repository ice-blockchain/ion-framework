// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/types/http_method.dart';
import 'package:ion_identity_client/src/signer/types/user_action_signing_request.dart';
import 'package:sprintf/sprintf.dart';

class SignDataSource {
  const SignDataSource(this.username);

  final String username;

  /// [keyId]
  static const signPath = '/keys/%s/signatures';

  UserActionSigningRequest buildSignSigningRequest({
    required Wallet wallet,
    required String message,
  }) {
    return UserActionSigningRequest(
      username: username,
      method: HttpMethod.post,
      path: sprintf(signPath, [wallet.signingKey]),
      body: _buildRequestBody(message),
    );
  }

  Map<String, dynamic> _buildRequestBody(String message) {
    return {
      'blockchainKind': 'Ion',
      'kind': 'Message',
      'message': message,
    };
  }
}

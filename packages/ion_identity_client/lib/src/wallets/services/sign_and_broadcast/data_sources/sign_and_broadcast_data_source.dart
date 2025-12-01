// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/types/http_method.dart';
import 'package:ion_identity_client/src/signer/types/user_action_signing_request.dart';
import 'package:sprintf/sprintf.dart';

class SignAndBroadcastDataSource {
  const SignAndBroadcastDataSource(this.username);

  final String username;

  /// [walletId]
  static const signAndBroadcastPath = '/wallets/%s/transactions';

  UserActionSigningRequest buildSignAndBroadcastSigningRequest({
    required Wallet wallet,
    required EvmBroadcastRequest request,
  }) {
    return UserActionSigningRequest(
      username: username,
      method: HttpMethod.post,
      path: sprintf(signAndBroadcastPath, [wallet.id]),
      body: _buildRequestBody(request),
    );
  }

  Map<String, dynamic> _buildRequestBody(EvmBroadcastRequest request) {
    return request.when(
      transactionHex: (transaction, kind, externalId) => {
        'kind': kind,
        'transaction': transaction,
        if (externalId != null) 'externalId': externalId,
      },
      transactionJson: (transaction, kind, externalId) => {
        'kind': kind,
        'transaction': transaction.toJson(),
        if (externalId != null) 'externalId': externalId,
      },
      userOperations: (userOperations, feeSponsorId, kind, externalId) => {
        'kind': kind,
        'userOperations': userOperations.map((op) => op.toJson()).toList(),
        'feeSponsorId': feeSponsorId,
        if (externalId != null) 'externalId': externalId,
      },
    );
  }
}

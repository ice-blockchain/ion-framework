// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/core/types/http_method.dart';
import 'package:ion_identity_client/src/signer/types/user_action_signing_request.dart';
import 'package:ion_identity_client/src/wallets/services/create_wallet/models/create_wallet_request.j.dart';

class CreateWalletDataSource {
  const CreateWalletDataSource();

  static const createWalletPath = '/wallets';

  UserActionSigningRequest buildCreateWalletSigningRequest({
    required String username,
    required String network,
    required String walletViewId,
  }) {
    return UserActionSigningRequest(
      username: username,
      method: HttpMethod.post,
      path: createWalletPath,
      body: CreateWalletRequest(
        network: network,
        name: walletViewId,
      ).toJson(),
    );
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/wallets/services/sign_and_broadcast/data_sources/sign_and_broadcast_data_source.dart';
import 'package:ion_identity_client/src/wallets/services/sign_and_broadcast/models/evm_broadcast_request.f.dart';

class SignAndBroadcastService {
  const SignAndBroadcastService({
    required SignAndBroadcastDataSource signAndBroadcastDataSource,
  }) : _signAndBroadcastDataSource = signAndBroadcastDataSource;

  final SignAndBroadcastDataSource _signAndBroadcastDataSource;

  Future<Map<String, dynamic>> signAndBroadcast({
    required Wallet wallet,
    required EvmBroadcastRequest request,
    required UserActionSignerNew signer,
  }) async {
    final signingRequest = _signAndBroadcastDataSource.buildSignAndBroadcastSigningRequest(
      wallet: wallet,
      request: request,
    );

    return signer.sign<Map<String, dynamic>>(
      signingRequest,
      (response) => response,
    );
  }
}

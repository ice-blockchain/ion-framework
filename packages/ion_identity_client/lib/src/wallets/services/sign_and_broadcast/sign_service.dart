// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/wallets/services/sign_and_broadcast/data_sources/sign_data_source.dart';

class SignService {
  const SignService({
    required SignDataSource signDataSource,
  }) : _signDataSource = signDataSource;

  final SignDataSource _signDataSource;

  Future<Map<String, dynamic>> sign({
    required Wallet wallet,
    required String message,
    required UserActionSignerNew signer,
  }) async {
    final signingRequest = _signDataSource.buildSignSigningRequest(
      wallet: wallet,
      message: message,
    );

    return signer.sign<Map<String, dynamic>>(
      signingRequest,
      (response) => response,
    );
  }
}

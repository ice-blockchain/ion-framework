// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/signer/user_action_signer.dart';
import 'package:ion_identity_client/src/wallets/services/make_transfer/data_sources/make_transfer_data_source.dart';

class MakeTransferService {
  const MakeTransferService({
    required MakeTransferDataSource makeTransferDataSource,
    required UserActionSigner userActionSigner,
  })  : _makeTransferDataSource = makeTransferDataSource,
        _userActionSigner = userActionSigner;

  final MakeTransferDataSource _makeTransferDataSource;
  final UserActionSigner _userActionSigner;

  Future<Map<String, dynamic>> makeTransfer({
    required Wallet wallet,
    required Transfer request,
    required OnVerifyIdentity<Map<String, dynamic>> onVerifyIdentity,
  }) async {
    final signingRequest = _makeTransferDataSource.buildTransferSigningRequest(
      wallet: wallet,
      transfer: request,
    );

    return onVerifyIdentity(
      onBiometricsFlow: ({
        required String localisedReason,
        required String localisedCancel,
      }) =>
          _userActionSigner.signWithBiometrics(
        signingRequest,
        (response) => response,
        localisedReason,
        localisedCancel,
      ),
      onPasswordFlow: ({
        required String password,
      }) =>
          _userActionSigner.signWithPassword(
        signingRequest,
        (response) => response,
        password,
      ),
      onPasskeyFlow: () => _userActionSigner.signWithPasskey(
        signingRequest,
        (response) => response,
      ),
    );
  }

  Future<Map<String, dynamic>> makeTransferWithSigner({
    required Wallet wallet,
    required Transfer request,
    required UserActionSignerNew signer,
  }) async {
    final signingRequest = _makeTransferDataSource.buildTransferSigningRequest(
      wallet: wallet,
      transfer: request,
    );

    return signer.sign(
      signingRequest,
      (response) => response,
    );
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/model/network_fee_type.dart';
import 'package:ion/app/features/wallets/model/nft_data.f.dart';
import 'package:ion/app/features/wallets/model/transfer_result.f.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_nft_use_case.r.g.dart';
part 'transfer_factory.dart';

@riverpod
Future<SendNftUseCase> sendNftUseCase(Ref ref) async {
  return SendNftUseCase(
    await ref.watch(ionIdentityClientProvider.future),
  );
}

class SendNftUseCase {
  SendNftUseCase(
    this._ionIdentityClient,
  );

  final IONIdentityClient _ionIdentityClient;

  bool isSendable(NftData sendableAsset) {
    try {
      _TransferFactory().create(
        receiverAddress: '',
        sendableAsset: sendableAsset,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<TransferResult> send({
    required Wallet senderWallet,
    required String receiverAddress,
    required NftData sendableAsset,
    required NetworkFeeType? networkFeeType,
    required OnVerifyIdentity<Map<String, dynamic>> onVerifyIdentity,
  }) async {
    final transfer = _TransferFactory().create(
      receiverAddress: receiverAddress,
      sendableAsset: sendableAsset,
      networkFeeType: networkFeeType,
    );
    final result = await _ionIdentityClient.wallets.makeTransfer(
      senderWallet,
      transfer,
      onVerifyIdentity,
    );

    return TransferResult.fromJson(result);
  }
}

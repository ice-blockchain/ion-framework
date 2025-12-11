// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/utils/evm_tx_builder.dart';

typedef IonIdentityClientResolver = Future<IONIdentityClient> Function();

class IonIdentityTransactionApi {
  IonIdentityTransactionApi({
    required IonIdentityClientResolver clientResolver,
  }) : _clientResolver = clientResolver;

  final IonIdentityClientResolver _clientResolver;

  Future<String> signAndBroadcast({
    required String walletId,
    required EvmTransaction transaction,
    required UserActionSignerNew userActionSigner,
  }) async {
    final client = await _clientResolver();
    final wallet = await _resolveWallet(client, walletId);

    final broadcastRequest = EvmBroadcastRequest.transactionJson(
      transaction: EvmTransactionJson(
        to: transaction.to,
        data: transaction.data.isNotEmpty ? transaction.data : null,
        value: _encodeQuantity(transaction.value),
        maxFeePerGas: _encodeQuantity(transaction.maxFeePerGas),
        maxPriorityFeePerGas: _encodeQuantity(transaction.maxPriorityFeePerGas),
      ),
    );

    final response = await client.wallets.signAndBroadcast(
      wallet,
      broadcastRequest,
      userActionSigner,
    );

    return _extractTransactionIdentifier(response);
  }




  Future<Wallet> _resolveWallet(IONIdentityClient client, String walletId) async {
    final wallets = await client.wallets.getWallets();
    final wallet = wallets.firstWhere(
      (candidate) => candidate.id == walletId,
      orElse: () => throw const IonSwapException('Wallet not found'),
    );
    return wallet;
  }

  String _extractTransactionIdentifier(Map<String, dynamic> response) {
    final txHash = response['txHash'] as String?;
    final id = response['id'] as String?;
    final transferId = response['transferId'] as String?;
    return txHash ??
        id ??
        transferId ??
        (throw StateError('Ion Identity response did not include a transaction identifier'));
  }

  String _encodeQuantity(BigInt value) {
    if (value == BigInt.zero) {
      return '0x0';
    }
    final encoded = value.toRadixString(16);
    return '0x$encoded';
  }
}

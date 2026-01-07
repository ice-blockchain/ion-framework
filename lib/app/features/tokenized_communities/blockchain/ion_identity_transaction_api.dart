// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/object.dart';
import 'package:ion/app/features/tokenized_communities/models/evm_transaction.dart';
import 'package:ion_identity_client/ion_identity.dart';

typedef IonIdentityClientResolver = Future<IONIdentityClient> Function();

class IonIdentityTransactionApi {
  IonIdentityTransactionApi({
    required IonIdentityClientResolver clientResolver,
  }) : _clientResolver = clientResolver;

  final IonIdentityClientResolver _clientResolver;

  Future<Map<String, dynamic>> signAndBroadcast({
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
        maxFeePerGas: transaction.maxFeePerGas?.let(_encodeQuantity),
        maxPriorityFeePerGas: transaction.maxPriorityFeePerGas?.let(_encodeQuantity),
      ),
    );

    final response = await client.wallets.signAndBroadcast(
      wallet,
      broadcastRequest,
      userActionSigner,
    );

    return response;
  }

  Future<Map<String, dynamic>> signAndBroadcastUserOperations({
    required String walletId,
    required List<EvmUserOperation> userOperations,
    required String feeSponsorId,
    required UserActionSignerNew userActionSigner,
    String? externalId,
  }) async {
    final client = await _clientResolver();
    final wallet = await _resolveWallet(client, walletId);

    final broadcastRequest = EvmBroadcastRequest.userOperations(
      userOperations: userOperations,
      feeSponsorId: feeSponsorId,
      externalId: externalId,
    );

    final response = await client.wallets.signAndBroadcast(
      wallet,
      broadcastRequest,
      userActionSigner,
    );

    return response;
  }

  Future<Wallet> _resolveWallet(IONIdentityClient client, String walletId) async {
    final wallets = await client.wallets.getWallets();
    final wallet = wallets.firstWhere(
      (candidate) => candidate.id == walletId,
      orElse: () => throw WalletNotFoundException(walletAddress: walletId),
    );
    return wallet;
  }

  String _encodeQuantity(BigInt value) {
    if (value == BigInt.zero) {
      return '0x0';
    }
    final encoded = value.toRadixString(16);
    return '0x$encoded';
  }
}

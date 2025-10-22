// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:http/http.dart' as http;
import 'package:ion_identity_client/src/wallets/services/broadcast_transaction/domain/transaction_creator/transaction_creator.dart';
import 'package:ion_identity_client/src/wallets/services/broadcast_transaction/models/transaction_request.dart';
import 'package:on_chain/on_chain.dart';

class TronTransactionCreator implements TransactionCreator {
  TronTransactionCreator({
    required this.url,
  });

  final String url;

  @override
  Future<Map<String, dynamic>> createTransaction(TransactionRequest request) async {
    final rpc = TronProvider(_TronHTTPProvider(url: url));
    final unsignedTxHex = await _createUnsignedTronTransaction(
      senderAddress: TronAddress(request.wallet.address!),
      receiverAddress: TronAddress(request.destinationAddress),
      amountSun: BigInt.parse(request.amount),
      tronProvider: rpc,
    );

    return {
      'kind': 'Transaction',
      'transaction': unsignedTxHex,
    };
  }
}

Future<String> _createUnsignedTronTransaction({
  required TronAddress senderAddress,
  required TronAddress receiverAddress,
  required BigInt amountSun,
  required TronProvider tronProvider,
  BigInt? feeLimit,
}) async {
  final contract = TransferContract(
    amount: amountSun,
    ownerAddress: senderAddress,
    toAddress: receiverAddress,
  );

  final parameter = Any(typeUrl: contract.typeURL, value: contract);
  final transactionContract = TransactionContract(
    type: contract.contractType,
    parameter: parameter,
  );

  final block = await tronProvider.request(TronRequestGetNowBlock());
  final blockHeader = block.blockHeader.rawData;

  final expiration = DateTime.now().toUtc().add(const Duration(hours: 12));

  final rawTx = TransactionRaw(
    refBlockBytes: blockHeader.refBlockBytes,
    refBlockHash: blockHeader.refBlockHash,
    expiration: BigInt.from(expiration.millisecondsSinceEpoch),
    feeLimit: feeLimit,
    contract: [transactionContract],
    timestamp: blockHeader.timestamp,
  );

  final unsignedTx = Transaction(rawData: rawTx, signature: []);

  final txBytes = unsignedTx.toBuffer();
  final txHex = '0x${BytesUtils.toHexString(txBytes)}';

  return txHex;
}

class _TronHTTPProvider implements TronServiceProvider {
  _TronHTTPProvider({
    required this.url,
    http.Client? client,
  }) : client = client ?? http.Client();

  final String url;
  final http.Client client;
  static const Duration defaultRequestTimeout = Duration(seconds: 30);

  @override
  Future<TronServiceResponse<T>> doRequest<T>(
    TronRequestDetails params, {
    Duration? timeout,
  }) async {
    final timeoutX = timeout ?? defaultRequestTimeout;
    if (params.type.isPostRequest) {
      final response = await client
          .post(params.toUri(url), headers: params.headers, body: params.body())
          .timeout(
        timeoutX,
        onTimeout: () {
          throw TimeoutException(
            'Tron HTTP provider post request timed out after ${timeoutX.inSeconds} seconds',
          );
        },
      );
      return params.toResponse(response.bodyBytes, response.statusCode);
    }
    final response = await client.get(params.toUri(url), headers: params.headers).timeout(
      timeoutX,
      onTimeout: () {
        throw TimeoutException(
          'Tron HTTP provider get request timed out after ${timeoutX.inSeconds} seconds',
        );
      },
    );
    return params.toResponse(response.bodyBytes, response.statusCode);
  }
}

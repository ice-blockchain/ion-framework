// SPDX-License-Identifier: ice License 1.0

import 'package:http/http.dart' as http;
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:web3dart/web3dart.dart';

mixin WaitForConfirmationMixin {
  Future<void> waitForConfirmation({
    required String txHash,
    required String rpcUrl,
    int maxTries = 20,
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    if (!txHash.startsWith('0x') || txHash.length != 66) {
      return;
    }

    final httpClient = http.Client();
    final web3Client = Web3Client(rpcUrl, httpClient);

    try {
      for (var i = 0; i < maxTries; i++) {
        final receipt = await web3Client.getTransactionReceipt(txHash);

        if (receipt != null) {
          if (receipt.status ?? false) {
            return;
          }

          throw IonSwapException(
            'Transaction failed on-chain, tx hash: $txHash, status: ${receipt.status}, from: ${receipt.from}, to: ${receipt.to}, gasUsed: ${receipt.gasUsed}, effectiveGasPrice: ${receipt.effectiveGasPrice}',
          );
        }

        await Future<void>.delayed(pollInterval);
      }

      throw IonSwapException(
        'Timed out waiting for transaction confirmation, tx hash: $txHash, rpcUrl: $rpcUrl',
      );
    } finally {
      await web3Client.dispose();
      httpClient.close();
    }
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/domain/swap/identifiers/swap_transaction_identifier.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/services/logger/logger.dart';

class BscSwapTxIdentifier extends SwapTransactionIdentifier {
  static const _bridgeContractAddress =
      '0x0000000000000000000000000000000000000000';

  @override
  String get networkId => 'bsc';

  @override
  String get bridgeAddress => _bridgeContractAddress;

  /// To-tx (ION → BSC): tx amount = swap.toAmount - (ionBridgeFee + ionMessageFee)
  @override
  bool isInTxAmountMatch(String expectedReceiveAmount, TransactionData tx) {
    final (expectedAmount, txAmountValue) = parseAmounts(expectedReceiveAmount, tx);
    if (expectedAmount == null || txAmountValue == null) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: InTxAmount - parse failed '
        '(expected: $expectedReceiveAmount, tx raw amount: null)',
      );
      return false;
    }
    if (expectedAmount == 0) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: InTxAmount - expected amount is 0',
      );
      return false;
    }

    // ION → BSC to-tx: tx amount = expected - (bridge fee + message fee)
    const totalFee =
        SwapTransactionIdentifier.ionBridgeFee + SwapTransactionIdentifier.ionMessageFee;
    final expectedTxAmount = expectedAmount - totalFee;
    final isMatch = amountsEqual(expectedTxAmount, txAmountValue);

    Logger.log(
      'SwapTxIdentifier[$networkId]: InTxAmount - '
      'expectedAmount: $expectedAmount, totalFee: $totalFee, '
      'expectedAfterFee: $expectedTxAmount, txAmount: $txAmountValue, match: $isMatch',
    );
    return isMatch;
  }
}

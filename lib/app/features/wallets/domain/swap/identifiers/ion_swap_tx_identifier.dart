// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/domain/swap/identifiers/swap_transaction_identifier.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/services/logger/logger.dart';

class IonSwapTxIdentifier extends SwapTransactionIdentifier {
  static const _bridgeMultisigAddress =
      'Uf8PSnTugXPqSS9HgrEWdrU1yOoy2wH4qCaqsZhCaV2HSIEw';

  @override
  String get networkId => 'ion';

  @override
  String get bridgeAddress => _bridgeMultisigAddress;

  /// First-leg (ION → any): tx amount = swap.amount - ionMessageFee
  @override
  bool isOutTxAmountMatch(String swapAmount, TransactionData tx) {
    final (swapAmountValue, txAmountValue) = parseAmounts(swapAmount, tx);
    if (swapAmountValue == null || txAmountValue == null) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: OutTxAmount - parse failed '
        '(swap: $swapAmount, tx raw amount: null)',
      );
      return false;
    }
    if (swapAmountValue == 0) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: OutTxAmount - swap amount is 0',
      );
      return false;
    }

    // ION first-leg: tx amount = swap amount - message fee
    final expectedTxAmount = swapAmountValue - SwapTransactionIdentifier.ionMessageFee;
    final isMatch = amountsEqual(expectedTxAmount, txAmountValue);

    Logger.log(
      'SwapTxIdentifier[$networkId]: OutTxAmount - '
      'swapAmount: $swapAmountValue, expectedAfterFee: $expectedTxAmount, '
      'txAmount: $txAmountValue, match: $isMatch',
    );
    return isMatch;
  }

  /// Second-leg (BSC → ION): tx amount = swap.toAmount - ionBridgeFee
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

    // BSC → ION second-leg: tx amount = expected - bridge fee only
    final expectedTxAmount = expectedAmount - SwapTransactionIdentifier.ionBridgeFee;
    final isMatch = amountsEqual(expectedTxAmount, txAmountValue);

    Logger.log(
      'SwapTxIdentifier[$networkId]: InTxAmount - '
      'expectedAmount: $expectedAmount, expectedAfterFee: $expectedTxAmount, '
      'txAmount: $txAmountValue, match: $isMatch',
    );
    return isMatch;
  }
}

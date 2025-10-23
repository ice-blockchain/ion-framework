// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_handlers/transfer_exception_handler.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';

class AptosExceptionHandler implements TransferExceptionHandler {
  @override
  IONException? tryHandle(
    String? reason,
    CoinData coin, {
    double? nativeTokenTotalBalance,
    double? nativeTokenTransferAmount,
  }) {
    if (!coin.network.isAptos) return null;

    if (reason != null) {
      final lower = reason.toLowerCase();

      if (lower.contains('insufficient_balance_for_transaction_fee')) {
        return InsufficientAmountException();
      }
    }

    return null;
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_handlers/transfer_exception_handler.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';

class BitcoinExceptionHandler implements TransferExceptionHandler {
  @override
  IONException? tryHandle(
    String? reason,
    CoinData coin, {
    double? nativeTokenTotalBalance,
    double? nativeTokenTransferAmount,
  }) {
    if (!coin.network.isBitcoin) return null;

    if (reason != null) {
      if (reason.toLowerCase().contains('dust')) {
        return InsufficientAmountException();
      }
    }

    return null;
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_handlers/transfer_exception_handler.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';

class CardanoExceptionHandler implements TransferExceptionHandler {
  @override
  IONException? tryHandle(String? reason, CoinData coin) {
    if (!coin.network.isCardano) return null;

    if (reason != null) {
      // Pattern: "Value 10000 less than the minimum UTXO value 849070"
      final utxoRegex = RegExp(r'Value \d+ less than the minimum UTXO value (\d+)');
      final match = utxoRegex.firstMatch(reason);

      if (match != null) {
        return InsufficientAmountException();
      }
    }

    return null;
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_handlers/transfer_exception_handler.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';

class PolkadotExceptionHandler implements TransferExceptionHandler {
  @override
  IONException? tryHandle(String? reason, CoinData coin) {
    if (!coin.network.isPolkadot) return null;

    return switch (reason) {
      'Token: BelowMinimum' => TokenBelowMinimumException(
          abbreviation: coin.abbreviation,
          minAmount: 0.2,
        ),
      _ => null,
    };
  }
}

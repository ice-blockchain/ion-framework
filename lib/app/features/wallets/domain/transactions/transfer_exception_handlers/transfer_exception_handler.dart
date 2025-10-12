// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';

abstract interface class TransferExceptionHandler {
  IONException? tryHandle(String? reason, CoinData coin);
}

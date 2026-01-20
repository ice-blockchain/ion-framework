// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/domain/swap/identifiers/swap_transaction_identifier.dart';

class BscSwapTxIdentifier extends SwapTransactionIdentifier {
  static const _bridgeContractAddress =
      '0x0000000000000000000000000000000000000000';

  @override
  String get networkId => 'bsc';

  @override
  String get bridgeAddress => _bridgeContractAddress;
}

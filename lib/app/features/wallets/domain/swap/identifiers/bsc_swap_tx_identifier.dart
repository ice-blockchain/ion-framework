// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/domain/swap/identifiers/swap_transaction_identifier.dart';

class BscSwapTxIdentifier extends SwapTransactionIdentifier {
  static const _swapContracts = ['0x4A04Ba2c7e11e929d62761165d863505bAf95C7F'];
  static const _burnAddresses = ['0x0000000000000000000000000000000000000000'];

  @override
  List<String> get networkIds => ['Bsc', 'BscTestnet'];

  @override
  List<String> get swapIndicatorAddresses => [..._swapContracts, ..._burnAddresses];
}

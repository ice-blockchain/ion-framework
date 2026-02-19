// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/domain/swap/identifiers/swap_transaction_identifier.dart';

class BscSwapTxIdentifier extends SwapTransactionIdentifier {
  BscSwapTxIdentifier({required this.ionSwapContractAddress});

  final String ionSwapContractAddress;

  static const _burnAddresses = ['0x0000000000000000000000000000000000000000'];

  @override
  List<String> get networkIds => ['Bsc', 'BscTestnet'];

  @override
  List<String> get swapIndicatorAddresses => [ionSwapContractAddress, ..._burnAddresses];
}

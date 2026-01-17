// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/domain/swap/identifiers/swap_transaction_identifier.dart';

class IonSwapTxIdentifier extends SwapTransactionIdentifier {
  static const _bridgeMultisigAddress =
      'Uf8PSnTugXPqSS9HgrEWdrU1yOoy2wH4qCaqsZhCaV2HSIEw';

  @override
  String get networkId => 'ion';

  @override
  String get bridgeAddress => _bridgeMultisigAddress;
}

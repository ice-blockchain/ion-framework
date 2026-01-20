// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/domain/swap/identifiers/swap_transaction_identifier.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';

class IonSwapTxIdentifier extends SwapTransactionIdentifier {
  static const _bridgeMultisigAddress = 'Uf8PSnTugXPqSS9HgrEWdrU1yOoy2wH4qCaqsZhCaV2HSIEw';

  /// ION message fee (in nanotons, 1 ION = 1_000_000_000 nanotons).
  /// Reference: https://docs.ton.org/foundations/fees
  static final BigInt _ionMessageFee = BigInt.from(60960000); // 0.06096 ION

  /// ION bridge fee (in nanotons).
  static final BigInt _ionBridgeFee = BigInt.from(500000000); // 0.5 ION

  @override
  String get networkId => 'ion';

  @override
  String get bridgeAddress => _bridgeMultisigAddress;

  @override
  BigInt getCrossChainFee({required bool isSource}) =>
      isSource ? (_ionBridgeFee + _ionMessageFee) : _ionBridgeFee;

  /// From-tx (ION → any): tx amount = swap.amount - ionMessageFee
  @override
  bool isOutTxAmountMatch(String swapAmount, TransactionData tx) {
    final (swapAmountValue, txAmountValue) = parseAmounts(swapAmount, tx);
    if (swapAmountValue == null || txAmountValue == null) return false;
    if (swapAmountValue == BigInt.zero) return false;

    final expectedTxAmount = swapAmountValue - _ionMessageFee;
    return amountsEqual(expectedTxAmount, txAmountValue);
  }
}

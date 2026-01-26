// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/expected_swap_data.f.dart';
import 'package:ion/app/features/wallets/model/swap_status.dart';
import 'package:ion/app/features/wallets/model/transaction_details.f.dart';

part 'swap_details.f.freezed.dart';

@freezed
class SwapDetails with _$SwapDetails {
  const factory SwapDetails({
    required int swapId,
    required String sellAmount,
    required String buyAmount,
    required DateTime createdAt,
    required SwapStatus status,
    required double exchangeRate,
    TransactionDetails? fromTransaction,
    TransactionDetails? toTransaction,
    ExpectedSwapData? expectedSellData,
    ExpectedSwapData? expectedBuyData,
  }) = _SwapDetails;
}

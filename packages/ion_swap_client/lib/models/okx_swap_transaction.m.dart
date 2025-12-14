// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'okx_swap_transaction.m.freezed.dart';
part 'okx_swap_transaction.m.g.dart';

@freezed
class OkxSwapTransaction with _$OkxSwapTransaction {
  factory OkxSwapTransaction({
    required String data,
    required String from,
    required String to,
    required String gas,
    required String gasPrice,
    required String value,
    String? maxPriorityFeePerGas,
    String? minReceiveAmount,
  }) = _OkxSwapTransaction;

  factory OkxSwapTransaction.fromJson(Map<String, dynamic> json) =>
      _$OkxSwapTransactionFromJson(json);
}

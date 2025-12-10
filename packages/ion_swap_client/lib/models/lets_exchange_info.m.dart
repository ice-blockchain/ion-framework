// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'lets_exchange_info.m.freezed.dart';
part 'lets_exchange_info.m.g.dart';

@freezed
class LetsExchangeInfo with _$LetsExchangeInfo {
  factory LetsExchangeInfo({
    @JsonKey(name: 'rate_id') required String rateId,
    @JsonKey(name: 'min_amount') required String minAmount,
    @JsonKey(name: 'max_amount') required String maxAmount,
    required String amount,
    required String fee,
    required String rate,
    required String profit,
    @JsonKey(name: 'withdrawal_fee') required String withdrawalFee,
    @JsonKey(name: 'extra_fee_amount') required String extraFeeAmount,
  }) = _LetsExchangeInfo;

  factory LetsExchangeInfo.fromJson(Map<String, dynamic> json) =>
      _$LetsExchangeInfoFromJson(json);
}

// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'bsc_fee_data.m.freezed.dart';
part 'bsc_fee_data.m.g.dart';

@freezed
class BscFeeData with _$BscFeeData {
  factory BscFeeData({
    required BigInt maxFeePerGas,
    required BigInt maxPriorityFeePerGas,
  }) = _BscFeeData;

  factory BscFeeData.fromJson(Map<String, dynamic> json) => _$BscFeeDataFromJson(json);
}

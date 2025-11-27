// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'exolix_rate.m.freezed.dart';
part 'exolix_rate.m.g.dart';

@freezed
class ExolixRate with _$ExolixRate {
  factory ExolixRate({
    required num fromAmount,
    required num toAmount,
    required num rate,
    required String? message,
    required num minAmount,
    required num withdrawMin,
    required num maxAmount,
  }) = _ExolixRate;

  factory ExolixRate.fromJson(Map<String, dynamic> json) => _$ExolixRateFromJson(json);
}

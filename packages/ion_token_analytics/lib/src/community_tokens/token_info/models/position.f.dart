// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'position.f.freezed.dart';
part 'position.f.g.dart';

@freezed
class Position with _$Position implements PositionBase {
  const factory Position({
    required int rank,
    required String amount,
    required double amountUSD,
    @Default(0) double pnl,
    @Default(0) double pnlPercentage,
  }) = _Position;

  const Position._();

  factory Position.fromJson(Map<String, dynamic> json) => _$PositionFromJson(json);

  double get amountValue {
    final value = BigInt.tryParse(amount);
    if (value == null) return 0;
    return value / BigInt.from(10).pow(18);
  }
}

abstract class PositionBase {
  int? get rank;
  String? get amount;
  double? get amountUSD;
  double? get pnl;
  double? get pnlPercentage;
}

@Freezed(copyWith: false)
class PositionPatch with _$PositionPatch implements PositionBase {
  const factory PositionPatch({
    int? rank,
    String? amount,
    double? amountUSD,
    double? pnl,
    double? pnlPercentage,
  }) = _PositionPatch;

  factory PositionPatch.fromJson(Map<String, dynamic> json) => _$PositionPatchFromJson(json);
}

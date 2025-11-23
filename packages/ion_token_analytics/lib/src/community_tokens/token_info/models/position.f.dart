// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'position.f.freezed.dart';
part 'position.f.g.dart';

@freezed
class Position with _$Position {
  const factory Position({
    required int rank,
    required double amount,
    required double amountUSD,
    required double pnl,
    required double pnlPercentage,
  }) = _Position;

  factory Position.fromJson(Map<String, dynamic> json) => _$PositionFromJson(json);
}

@Freezed(copyWith: false)
class PositionPatch with _$PositionPatch {
  const factory PositionPatch({int? rank, double? amount, double? amountUSD, double? pnl, double? pnlPercentage}) =
      _PositionPatch;

  factory PositionPatch.fromJson(Map<String, dynamic> json) => _$PositionPatchFromJson(json);
}

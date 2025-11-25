// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/patch.dart';

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
class PositionPatch with _$PositionPatch, Patch<Position> {
  const PositionPatch._();

  const factory PositionPatch({
    int? rank,
    double? amount,
    double? amountUSD,
    double? pnl,
    double? pnlPercentage,
  }) = _PositionPatch;

  factory PositionPatch.fromJson(Map<String, dynamic> json) => _$PositionPatchFromJson(json);

  @override
  Position merge(Position original) {
    return original.copyWith(
      rank: rank ?? original.rank,
      amount: amount ?? original.amount,
      amountUSD: amountUSD ?? original.amountUSD,
      pnl: pnl ?? original.pnl,
      pnlPercentage: pnlPercentage ?? original.pnlPercentage,
    );
  }

  @override
  Position? toEntityOrNull() {
    if (rank == null ||
        amount == null ||
        amountUSD == null ||
        pnl == null ||
        pnlPercentage == null) {
      return null;
    }

    return Position(
      rank: rank!,
      amount: amount!,
      amountUSD: amountUSD!,
      pnl: pnl!,
      pnlPercentage: pnlPercentage!,
    );
  }
}

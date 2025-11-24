// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/patch.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/position.f.dart';

part 'position_patch.f.freezed.dart';
part 'position_patch.f.g.dart';

@freezed
class PositionPatch with _$PositionPatch, Patch<Position> {
  const factory PositionPatch({
    int? rank,
    double? amount,
    double? amountUSD,
    double? pnl,
    double? pnlPercentage,
  }) = _PositionPatch;

  const PositionPatch._();

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

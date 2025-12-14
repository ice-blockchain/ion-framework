// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/core/map_utils.dart';

part 'bonding_curve_progress.f.freezed.dart';
part 'bonding_curve_progress.f.g.dart';

abstract class BondingCurveProgressBase {
  int? get currentAmount;

  double? get currentAmountUSD;

  int? get goalAmount;

  double? get goalAmountUSD;

  bool? get migrated;

  int? get raisedAmount;
}

@freezed
class BondingCurveProgress with _$BondingCurveProgress implements BondingCurveProgressBase {
  const factory BondingCurveProgress({
    required int currentAmount,
    required double currentAmountUSD,
    required int goalAmount,
    required double goalAmountUSD,
    required bool migrated,
    required int raisedAmount,
  }) = _BondingCurveProgress;

  factory BondingCurveProgress.fromJson(Map<String, dynamic> json) =>
      _$BondingCurveProgressFromJson(json);
}

@Freezed(copyWith: false)
class BondingCurveProgressPatch
    with _$BondingCurveProgressPatch
    implements BondingCurveProgressBase {
  const factory BondingCurveProgressPatch({
    int? currentAmount,
    double? currentAmountUSD,
    int? goalAmount,
    double? goalAmountUSD,
    bool? migrated,
    int? raisedAmount,
  }) = _BondingCurveProgressPatch;

  factory BondingCurveProgressPatch.fromJson(Map<String, dynamic> json) =>
      _$BondingCurveProgressPatchFromJson(json);
}

extension BondingCurveProgressPatchExtension on BondingCurveProgressPatch {
  bool isEmpty() {
    return currentAmount == null &&
        currentAmountUSD == null &&
        goalAmount == null &&
        goalAmountUSD == null &&
        migrated == null &&
        raisedAmount == null;
  }
}

extension BondingCurveProgressExtension on BondingCurveProgress {
  BondingCurveProgress merge(BondingCurveProgressPatch patch) {
    final mergedJson = deepMerge(toJson(), patch.toJson());
    return BondingCurveProgress.fromJson(mergedJson);
  }
}

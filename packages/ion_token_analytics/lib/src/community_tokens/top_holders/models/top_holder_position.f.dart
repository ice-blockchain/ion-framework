// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/creator.f.dart';

part 'top_holder_position.f.freezed.dart';
part 'top_holder_position.f.g.dart';

abstract class TopHolderPositionBase {
  CreatorBase? get holder;

  int? get rank;

  String? get amount;

  double? get amountUSD;

  double? get supplyShare;
}

@freezed
class TopHolderPosition with _$TopHolderPosition implements TopHolderPositionBase {
  const factory TopHolderPosition({
    required CreatorPatch holder,
    required int rank,
    required String amount,
    required double amountUSD,
    required double supplyShare,
  }) = _TopHolderPosition;

  factory TopHolderPosition.fromJson(Map<String, dynamic> json) =>
      _$TopHolderPositionFromJson(json);
}

@Freezed(copyWith: false)
class TopHolderPositionPatch with _$TopHolderPositionPatch implements TopHolderPositionBase {
  const factory TopHolderPositionPatch({
    CreatorPatch? holder,
    int? rank,
    String? amount,
    double? amountUSD,
    double? supplyShare,
  }) = _TopHolderPositionPatch;

  factory TopHolderPositionPatch.fromJson(Map<String, dynamic> json) =>
      _$TopHolderPositionPatchFromJson(json);
}

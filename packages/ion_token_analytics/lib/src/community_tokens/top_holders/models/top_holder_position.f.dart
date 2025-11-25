// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/addresses.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/creator.f.dart';

part 'top_holder_position.f.freezed.dart';
part 'top_holder_position.f.g.dart';

abstract class TopHolderPositionBase {
  CreatorBase? get holder;
  String? get type;
  int? get rank;
  double? get amount;
  double? get amountUSD;
  double? get supplyShare;
  AddressesBase? get addresses;
}

@freezed
class TopHolderPosition with _$TopHolderPosition implements TopHolderPositionBase {
  const factory TopHolderPosition({
    required Creator holder,
    required String type,
    required int rank,
    required double amount,
    required double amountUSD,
    required double supplyShare,
    required Addresses addresses,
  }) = _TopHolderPosition;

  factory TopHolderPosition.fromJson(Map<String, dynamic> json) =>
      _$TopHolderPositionFromJson(json);
}

@Freezed(copyWith: false)
class TopHolderPositionPatch with _$TopHolderPositionPatch implements TopHolderPositionBase {
  const factory TopHolderPositionPatch({
    CreatorPatch? holder,
    String? type,
    int? rank,
    double? amount,
    double? amountUSD,
    double? supplyShare,
    AddressesPatch? addresses,
  }) = _TopHolderPositionPatch;

  factory TopHolderPositionPatch.fromJson(Map<String, dynamic> json) =>
      _$TopHolderPositionPatchFromJson(json);
}

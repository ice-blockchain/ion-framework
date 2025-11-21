// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/addresses.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/creator.f.dart';

part 'top_holder_position.f.freezed.dart';
part 'top_holder_position.f.g.dart';

@freezed
class TopHolderPosition with _$TopHolderPosition {
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

// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/market_data.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/patch.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/position_patch.f.dart';

part 'market_data_patch.f.freezed.dart';
part 'market_data_patch.f.g.dart';

@freezed
class MarketDataPatch with _$MarketDataPatch, Patch<MarketData> {
  const factory MarketDataPatch({
    double? marketCap,
    double? volume,
    int? holders,
    double? priceUSD,
    PositionPatch? position,
  }) = _MarketDataPatch;

  const MarketDataPatch._();

  factory MarketDataPatch.fromJson(Map<String, dynamic> json) => _$MarketDataPatchFromJson(json);

  @override
  MarketData merge(MarketData original) {
    return original.copyWith(
      marketCap: marketCap ?? original.marketCap,
      volume: volume ?? original.volume,
      holders: holders ?? original.holders,
      priceUSD: priceUSD ?? original.priceUSD,
      // Optional nested patch:
      position: position != null && original.position != null
          ? position!.merge(original.position!)
          : position?.toEntityOrNull() ?? original.position,
    );
  }
}

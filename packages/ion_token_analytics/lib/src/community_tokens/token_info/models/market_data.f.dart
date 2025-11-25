// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/patch.dart';

part 'market_data.f.freezed.dart';
part 'market_data.f.g.dart';

@freezed
class MarketData with _$MarketData {
  const factory MarketData({
    required double marketCap,
    required double volume,
    required int holders,
    required double priceUSD,
    Position? position,
  }) = _MarketData;

  factory MarketData.fromJson(Map<String, dynamic> json) => _$MarketDataFromJson(json);
}

@Freezed(copyWith: false)
class MarketDataPatch with _$MarketDataPatch, Patch<MarketData> {
  const MarketDataPatch._();

  const factory MarketDataPatch({
    double? marketCap,
    double? volume,
    int? holders,
    double? priceUSD,
    PositionPatch? position,
  }) = _MarketDataPatch;

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

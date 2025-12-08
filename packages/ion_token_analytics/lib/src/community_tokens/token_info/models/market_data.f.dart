// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';

part 'market_data.f.freezed.dart';
part 'market_data.f.g.dart';

abstract class MarketDataBase {
  String? get ticker;
  double? get marketCap;
  double? get volume;
  int? get holders;
  double? get priceUSD;
  PositionBase? get position;
}

@freezed
class MarketData with _$MarketData implements MarketDataBase {
  const factory MarketData({
    required double marketCap,
    required double volume,
    required int holders,
    required double priceUSD,
    String? ticker,
    Position? position,
  }) = _MarketData;

  factory MarketData.fromJson(Map<String, dynamic> json) => _$MarketDataFromJson(json);
}

@Freezed(copyWith: false)
class MarketDataPatch with _$MarketDataPatch implements MarketDataBase {
  const factory MarketDataPatch({
    String? ticker,
    double? marketCap,
    double? volume,
    int? holders,
    double? priceUSD,
    PositionPatch? position,
  }) = _MarketDataPatch;

  factory MarketDataPatch.fromJson(Map<String, dynamic> json) => _$MarketDataPatchFromJson(json);
}

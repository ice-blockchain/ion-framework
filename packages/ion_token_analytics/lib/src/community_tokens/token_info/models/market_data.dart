// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/position.dart';

part 'market_data.freezed.dart';
part 'market_data.g.dart';

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

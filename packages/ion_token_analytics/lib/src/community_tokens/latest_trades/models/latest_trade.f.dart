// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/latest_trades/models/trade_position.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/creator.f.dart';

part 'latest_trade.f.freezed.dart';
part 'latest_trade.f.g.dart';

@freezed
class LatestTrade with _$LatestTrade implements LatestTradePatch {
  const factory LatestTrade({required Creator creator, required TradePosition position}) =
      _LatestTrade;

  factory LatestTrade.fromJson(Map<String, dynamic> json) => _$LatestTradeFromJson(json);
}

@Freezed(copyWith: false)
class LatestTradePatch with _$LatestTradePatch {
  const factory LatestTradePatch({CreatorPatch? creator, TradePositionPatch? position}) =
      _LatestTradePatch;

  factory LatestTradePatch.fromJson(Map<String, dynamic> json) => _$LatestTradePatchFromJson(json);
}

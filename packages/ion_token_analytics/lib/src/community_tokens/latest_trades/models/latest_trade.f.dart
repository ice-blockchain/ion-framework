// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/addresses.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/creator.f.dart';

part 'latest_trade.f.freezed.dart';
part 'latest_trade.f.g.dart';

@freezed
class LatestTrade with _$LatestTrade {
  const factory LatestTrade({
    required Creator trader,
    required double amount,
    required double amountUSD,
    required int timestamp,
    required String side, // "buy" or "sell"
    required Addresses addresses,
  }) = _LatestTrade;

  factory LatestTrade.fromJson(Map<String, dynamic> json) => _$LatestTradeFromJson(json);
}

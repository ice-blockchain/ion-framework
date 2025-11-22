// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/addresses.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/creator.f.dart';

part 'trade_position.f.freezed.dart';
part 'trade_position.f.g.dart';

@freezed
class TradePosition with _$TradePosition {
  const factory TradePosition({
    required Creator holder,
    required Addresses addresses,
    required String createdAt,
    required String type, // "buy/sell"
    required double amount,
    required double amountUSD,
    required double balance,
    required double balanceUSD,
  }) = _TradePosition;

  factory TradePosition.fromJson(Map<String, dynamic> json) => _$TradePositionFromJson(json);
}

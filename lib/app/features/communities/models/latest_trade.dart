// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';

enum TradeSide { buy, sell }

class LatestTradeViewData {
  const LatestTradeViewData({
    required this.displayName,
    required this.handle,
    required this.amount,
    required this.usd,
    required this.time,
    required this.side,
    this.avatarUrl,
    this.verified = false,
  });

  factory LatestTradeViewData.fromLatestTrade(LatestTrade trade) {
    final trader = trade.trader;
    final handle = trader.name.isNotEmpty ? '@${trader.name}' : '';
    final side = trade.side == 'buy' ? TradeSide.buy : TradeSide.sell;
    final time = DateTime.fromMillisecondsSinceEpoch(trade.timestamp, isUtc: true);

    return LatestTradeViewData(
      displayName: trader.display,
      handle: handle,
      amount: trade.amount,
      usd: trade.amountUSD,
      time: time,
      side: side,
      avatarUrl: trader.avatar,
      verified: trader.verified,
    );
  }

  final String displayName;
  final String handle; // can be empty for address-only
  final String? avatarUrl;
  final double amount;
  final double usd;
  final DateTime time;
  final TradeSide side;
  final bool verified;
}

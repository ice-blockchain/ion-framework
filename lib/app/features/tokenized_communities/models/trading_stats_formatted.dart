// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TradingStatsFormatted {
  const TradingStatsFormatted({
    required this.volumeText,
    required this.buysText,
    required this.sellsText,
    required this.netBuyText,
    required this.isNetBuyPositive,
    required this.hasNoSells,
    required this.hasZeroNetBuy,
  });

  factory TradingStatsFormatted.fromStats(TradingStats stats) {
    final volumeText = MarketDataFormatter.formatCompactOrSubscript(stats.volumeUSD);

    final buysAmount = MarketDataFormatter.formatCompactOrSubscript(stats.buysTotalAmountUSD);
    final buysText = '${stats.numberOfBuys}/$buysAmount';

    final sellsAmount = MarketDataFormatter.formatCompactOrSubscript(stats.sellsTotalAmountUSD);
    final sellsText = '${stats.numberOfSells}/$sellsAmount';
    final hasNoSells = stats.numberOfSells == 0 && stats.sellsTotalAmountUSD == 0;

    final netBuyFormatted = MarketDataFormatter.formatCompactOrSubscript(stats.netBuy.abs());
    final hasZeroNetBuy = stats.netBuy == 0.0;
    final netBuyText =
        hasZeroNetBuy ? netBuyFormatted : getNumericSign(stats.netBuy) + netBuyFormatted;

    return TradingStatsFormatted(
      volumeText: volumeText,
      buysText: buysText,
      sellsText: sellsText,
      netBuyText: netBuyText,
      isNetBuyPositive: stats.netBuy >= 0,
      hasNoSells: hasNoSells,
      hasZeroNetBuy: hasZeroNetBuy,
    );
  }

  final String volumeText;
  final String buysText;
  final String sellsText;
  final String netBuyText;
  final bool isNetBuyPositive;
  final bool hasNoSells;
  final bool hasZeroNetBuy;
}

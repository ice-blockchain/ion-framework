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
    required this.isSellsZero,
    required this.isNetBuyZero,
  });

  factory TradingStatsFormatted.fromStats(TradingStats stats) {
    final volumeText = stats.volumeUSD == 0
        ? '--'
        : r'$' + MarketDataFormatter.formatCompactNumber(stats.volumeUSD);

    final buysText = (stats.numberOfBuys == 0 && stats.buysTotalAmountUSD == 0)
        ? '--'
        : '${stats.numberOfBuys}/\$${MarketDataFormatter.formatCompactNumber(stats.buysTotalAmountUSD)}';

    final sellsAmount = MarketDataFormatter.formatCompactNumber(stats.sellsTotalAmountUSD);
    final sellsText = '${stats.numberOfSells}/\$$sellsAmount';
    final isSellsZero = stats.numberOfSells == 0 && stats.sellsTotalAmountUSD == 0;

    final netBuyFormatted = MarketDataFormatter.formatCompactNumber(stats.netBuy.abs());
    final netBuyText = getNumericSign(stats.netBuy) + netBuyFormatted;
    final isNetBuyZero = stats.netBuy == 0.0;

    return TradingStatsFormatted(
      volumeText: volumeText,
      buysText: buysText,
      sellsText: sellsText,
      netBuyText: netBuyText,
      isNetBuyPositive: stats.netBuy >= 0,
      isSellsZero: isSellsZero,
      isNetBuyZero: isNetBuyZero,
    );
  }

  final String volumeText;
  final String buysText;
  final String sellsText;
  final String netBuyText;
  final bool isNetBuyPositive;
  final bool isSellsZero;
  final bool isNetBuyZero;
}

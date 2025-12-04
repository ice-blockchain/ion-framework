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
  });

  factory TradingStatsFormatted.fromStats(TradingStats stats) {
    final volumeText = r'$' + MarketDataFormatter.formatCompactNumber(stats.volumeUSD);

    final buysAmount = MarketDataFormatter.formatCompactNumber(stats.buysTotalAmountUSD);
    final buysText = '${stats.numberOfBuys}/\$$buysAmount';

    final sellsAmount = MarketDataFormatter.formatCompactNumber(stats.sellsTotalAmountUSD);
    final sellsText = '${stats.numberOfSells}/\$$sellsAmount';

    final netBuyFormatted = MarketDataFormatter.formatCompactNumber(stats.netBuy.abs());
    final netBuyText = getNumericSign(stats.netBuy) + netBuyFormatted;

    return TradingStatsFormatted(
      volumeText: volumeText,
      buysText: buysText,
      sellsText: sellsText,
      netBuyText: netBuyText,
      isNetBuyPositive: stats.netBuy >= 0,
    );
  }

  final String volumeText;
  final String buysText;
  final String sellsText;
  final String netBuyText;
  final bool isNetBuyPositive;
}

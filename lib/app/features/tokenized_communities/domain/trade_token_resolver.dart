// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/data/models/tokenized_communities_trade_config.f.dart';

class TradeTokenResolver {
  const TradeTokenResolver({
    required TokenizedCommunitiesTradeConfig tradeConfig,
  }) : _tradeConfig = tradeConfig;

  final TokenizedCommunitiesTradeConfig _tradeConfig;

  bool isIonTokenAddress(String address) {
    return _normalize(address) == _normalize(_tradeConfig.pancakeSwapIonTokenAddress);
  }

  String _normalize(String address) {
    return address.trim().toLowerCase();
  }
}

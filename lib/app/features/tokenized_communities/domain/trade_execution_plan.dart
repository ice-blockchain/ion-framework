// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/domain/trade_quote_builder.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_route_builder.dart';

class TradeExecutionPlan {
  const TradeExecutionPlan({
    required this.route,
    required this.quote,
  });

  final TradeRoutePlan route;
  final TradeQuotePlan quote;
}

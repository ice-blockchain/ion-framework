// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tokenized_communities_trade_config.f.freezed.dart';
part 'tokenized_communities_trade_config.f.g.dart';

@freezed
class TokenizedCommunitiesTradeConfig with _$TokenizedCommunitiesTradeConfig {
  const factory TokenizedCommunitiesTradeConfig({
    required String pancakeSwapWbnbAddress,
    required String pancakeSwapIonTokenAddress,
    required String pancakeSwapSwapRouterAddress,
    required String pancakeSwapQuoterV2Address,
    required int pancakeSwapFeeTier,
    @Default(18) int ionTokenDecimals,
  }) = _TokenizedCommunitiesTradeConfig;

  factory TokenizedCommunitiesTradeConfig.fromJson(Map<String, dynamic> json) =>
      _$TokenizedCommunitiesTradeConfigFromJson(json);
}

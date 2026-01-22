// SPDX-License-Identifier: ice License 1.0

class TokenizedCommunitiesTradeConfig {
  const TokenizedCommunitiesTradeConfig({
    required this.pancakeSwapWbnbAddress,
    required this.pancakeSwapIonTokenAddress,
    required this.pancakeSwapSwapRouterAddress,
    required this.pancakeSwapQuoterV2Address,
    required this.pancakeSwapFeeTier,
    required this.ionTokenDecimals,
  });

  final String pancakeSwapWbnbAddress;
  final String pancakeSwapIonTokenAddress;
  final String pancakeSwapSwapRouterAddress;
  final String pancakeSwapQuoterV2Address;
  final int pancakeSwapFeeTier;
  final int ionTokenDecimals;
}

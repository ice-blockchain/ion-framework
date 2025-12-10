// SPDX-License-Identifier: ice License 1.0

class TokenizedCommunitiesConstants {
  TokenizedCommunitiesConstants._();

  static const int creatorTokenDecimals = 18;
  static const String bscNetworkId = 'Bsc';
  static const String bscTestnetNetworkId = 'BscTestnet';

  static const double defaultSlippagePercent = 1;
  static final BigInt defaultMaxFeePerGas = BigInt.from(20000000000); // 20 gwei
  static final BigInt defaultMaxPriorityFeePerGas = BigInt.from(1000000000); // 1 gwei

  static const int approvalTrillionMultiplier = 12; // 10^12
  static const int maxSlippagePercent = 100;
  static const int basisPointsScale = 10000;
  static const int percentToBasisPointsMultiplier = 100;

  static const int quoteDebounceMilliseconds = 500;
  static const int percentageDivisor = 100;
}

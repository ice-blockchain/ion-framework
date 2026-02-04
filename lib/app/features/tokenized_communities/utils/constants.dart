// SPDX-License-Identifier: ice License 1.0

class TokenizedCommunitiesConstants {
  TokenizedCommunitiesConstants._();

  static const int creatorTokenDecimals = 18;
  static const String bscNetworkId = 'Bsc';
  static const String bscTestnetNetworkId = 'BscTestnet';

  /// Identity fee sponsor wallet id used for sponsored user-operations broadcasts.
  static const String tradeFeeSponsorWalletId = 'fs-01jg7-2dotc-esmbtjcn9udvpvk8';

  static const double defaultSlippagePercent = 5;

  static const int approvalTrillionMultiplier = 12; // 10^12
  static const int maxSlippagePercent = 100;
  static const int basisPointsScale = 10000;
  static const int percentToBasisPointsMultiplier = 100;

  static const int quoteDebounceMilliseconds = 500;
  static const int percentageDivisor = 100;
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';

class CommunityTokenBuyRequest {
  CommunityTokenBuyRequest({
    required this.ionConnectAddress,
    required this.amountIn,
    required this.slippagePercent,
    required this.walletId,
    required this.walletAddress,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.baseTokenAddress,
    required this.tokenDecimals,
    required this.userActionSigner,
  });

  final String ionConnectAddress;
  final BigInt amountIn;
  final double slippagePercent;
  final String walletId;
  final String walletAddress;
  final BigInt maxFeePerGas;
  final BigInt maxPriorityFeePerGas;
  final String baseTokenAddress;
  final int tokenDecimals;
  final UserActionSignerNew userActionSigner;
}

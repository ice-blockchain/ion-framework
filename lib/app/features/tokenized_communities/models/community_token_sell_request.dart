// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';

class CommunityTokenSellRequest {
  CommunityTokenSellRequest({
    required this.externalAddress,
    required this.amountIn,
    required this.slippagePercent,
    required this.walletId,
    required this.walletAddress,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.paymentTokenAddress,
    required this.communityTokenAddress,
    required this.tokenDecimals,
    required this.userActionSigner,
    this.contractAddress,
  });

  final String externalAddress;
  final String? contractAddress;

  final BigInt amountIn;
  final double slippagePercent;
  final String walletId;
  final String walletAddress;
  final BigInt maxFeePerGas;
  final BigInt maxPriorityFeePerGas;
  final String paymentTokenAddress;
  final String communityTokenAddress;
  final int tokenDecimals;
  final UserActionSignerNew userActionSigner;

  String get tokenAddress {
    return contractAddress ?? externalAddress;
  }
}

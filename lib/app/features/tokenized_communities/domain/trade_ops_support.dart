// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_repository.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/tokenized_communities/utils/fat_address_v2.dart';
import 'package:ion_identity_client/ion_identity.dart';

class TradeOpsSupport {
  TradeOpsSupport({
    required this.repository,
  });

  final TradeCommunityTokenRepository repository;

  Future<EvmUserOperation?> buildAllowanceApprovalOperationIfNeeded({
    required String owner,
    required String tokenAddress,
    required BigInt requiredAmount,
    required int tokenDecimals,
    String? spender,
  }) async {
    final allowance = await repository.fetchAllowance(
      owner: owner,
      tokenAddress: tokenAddress,
      spender: spender,
    );

    if (allowance >= requiredAmount) return null;

    final approvalAmount = BigInt.from(10).pow(
      TokenizedCommunitiesConstants.approvalTrillionMultiplier + tokenDecimals,
    );

    return repository.buildApproveUserOperation(
      tokenAddress: tokenAddress,
      amount: approvalAmount,
      spender: spender,
    );
  }

  BigInt calculateMinReturn({
    required BigInt expectedOut,
    required double slippagePercent,
  }) {
    final normalized = slippagePercent.clamp(
      0,
      TokenizedCommunitiesConstants.maxSlippagePercent,
    );
    final slippageBps = (normalized * TokenizedCommunitiesConstants.percentToBasisPointsMultiplier)
        .round()
        .clamp(0, TokenizedCommunitiesConstants.basisPointsScale);
    final multiplier = TokenizedCommunitiesConstants.basisPointsScale - slippageBps;
    return (expectedOut * BigInt.from(multiplier)) ~/
        BigInt.from(TokenizedCommunitiesConstants.basisPointsScale);
  }

  List<int> buildBuyToTokenBytes({
    required String externalAddress,
    required String? tokenAddress,
    required FatAddressV2Data? fatAddressData,
  }) {
    if (tokenAddress != null && tokenAddress.isNotEmpty) {
      return getBytesFromAddress(tokenAddress);
    }
    if (fatAddressData == null) {
      throw StateError('fatAddressData is required for first buy of $externalAddress');
    }
    return fatAddressData.toBytes();
  }

  List<int> getBytesFromAddress(String address) {
    if (address.startsWith('0x')) {
      return _hexToBytes(address);
    }
    return utf8.encode(address);
  }

  List<int> _hexToBytes(String hex) {
    var hexStr = hex;
    if (hexStr.startsWith('0x')) {
      hexStr = hexStr.substring(2);
    }
    if (hexStr.length % 2 != 0) {
      hexStr = '0$hexStr';
    }
    final result = <int>[];
    for (var i = 0; i < hexStr.length; i += 2) {
      final byte = int.parse(hexStr.substring(i, i + 2), radix: 16);
      result.add(byte);
    }
    return result;
  }
}

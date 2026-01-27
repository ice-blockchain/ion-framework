// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/evm_tx_builder.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/ion_identity_transaction_api.dart';
import 'package:ion/app/features/tokenized_communities/data/token_info_cache.dart';
import 'package:ion/app/features/tokenized_communities/data/trade_community_token_api.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_service.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/models/evm_transaction.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TradeCommunityTokenRepository {
  TradeCommunityTokenRepository({
    required this.txBuilder,
    required this.ionIdentity,
    required this.api,
    required TokenInfoCache tokenInfoCache,
  }) : _tokenInfoCache = tokenInfoCache;

  final EvmTxBuilder txBuilder;
  final IonIdentityTransactionApi ionIdentity;
  final TradeCommunityTokenApi api;

  String? _cachedAbi;
  String? _cachedAddress;

  final TokenInfoCache _tokenInfoCache;

  Future<void> _ensureConfigLoaded() async {
    if (_cachedAbi != null && _cachedAddress != null) return;
    _cachedAbi = await api.fetchBondingCurveAbi();
    _cachedAddress = await api.fetchBondingCurveAddress();
  }

  Future<CommunityToken?> fetchTokenInfo(String externalAddress) async {
    return _tokenInfoCache.get(externalAddress);
  }

  Future<CommunityToken?> fetchTokenInfoFresh(String externalAddress) async {
    return _tokenInfoCache.refresh(externalAddress);
  }

  Future<String> fetchBondingCurveAddress() async {
    await _ensureConfigLoaded();
    return _cachedAddress!;
  }

  Future<PricingResponse> fetchPricing({
    required String pricingIdentifier,
    required CommunityTokenTradeMode mode,
    required String amount,
  }) async {
    final pricing = await api.fetchPricing(pricingIdentifier, mode.apiType, amount);
    if (pricing == null) {
      throw TokenPricingNotFoundException(pricingIdentifier);
    }
    return pricing;
  }

  Future<BigInt> fetchAllowance({
    required String owner,
    required String tokenAddress,
  }) async {
    await _ensureConfigLoaded();
    return txBuilder.allowance(
      token: tokenAddress,
      owner: owner,
      spender: _cachedAddress!,
    );
  }

  Future<EvmUserOperation> buildApproveUserOperation({
    required String tokenAddress,
    required BigInt amount,
  }) async {
    await _ensureConfigLoaded();
    final approvalTx = await txBuilder.encodeApprove(
      token: tokenAddress,
      spender: _cachedAddress!,
      amount: amount,
    );

    return _toUserOperation(approvalTx);
  }

  Future<EvmUserOperation> buildSwapUserOperation({
    required List<int> fromTokenIdentifier,
    required List<int> toTokenIdentifier,
    required BigInt amountIn,
    required BigInt minReturn,
  }) async {
    await _ensureConfigLoaded();
    final swapTx = await txBuilder.encodeSwap(
      fromTokenIdentifier: fromTokenIdentifier,
      toTokenIdentifier: toTokenIdentifier,
      amountIn: amountIn,
      minReturn: minReturn,
      bondingCurveAbi: _cachedAbi!,
      bondingCurveAddress: _cachedAddress!,
    );

    return _toUserOperation(swapTx);
  }

  Future<EvmUserOperation> buildUpdateMetadataUserOperation({
    required String tokenAddress,
    required String newName,
    required String newSymbol,
  }) async {
    final tokenAbi = await txBuilder.contracts.loadTokenMetadataAbi();
    final updateTx = await txBuilder.encodeUpdateMetadata(
      tokenAddress: tokenAddress,
      newName: newName,
      newSymbol: newSymbol,
      tokenAbi: tokenAbi,
    );

    return _toUserOperation(updateTx);
  }

  Future<String> fetchTokenMetadataOwner(String tokenAddress) async {
    final tokenAbi = await txBuilder.contracts.loadTokenMetadataAbi();
    final owner = await txBuilder.getTokenMetadataOwner(
      tokenAddress: tokenAddress,
      tokenAbi: tokenAbi,
    );
    return owner.hex;
  }

  Future<String> fetchTokenName(String tokenAddress) async {
    final tokenAbi = await txBuilder.contracts.loadTokenMetadataAbi();
    return txBuilder.getTokenName(
      tokenAddress: tokenAddress,
      tokenAbi: tokenAbi,
    );
  }

  Future<String> fetchTokenSymbol(String tokenAddress) async {
    final tokenAbi = await txBuilder.contracts.loadTokenMetadataAbi();
    return txBuilder.getTokenSymbol(
      tokenAddress: tokenAddress,
      tokenAbi: tokenAbi,
    );
  }

  Future<TransactionResult> signAndBroadcastUserOperations({
    required String walletId,
    required List<EvmUserOperation> userOperations,
    required String feeSponsorId,
    required UserActionSignerNew userActionSigner,
    String? externalId,
  }) {
    return ionIdentity.signAndBroadcastUserOperations(
      walletId: walletId,
      userOperations: userOperations,
      feeSponsorId: feeSponsorId,
      userActionSigner: userActionSigner,
      externalId: externalId,
    );
  }

  EvmUserOperation _toUserOperation(EvmTransaction transaction) {
    return EvmUserOperation(
      to: transaction.to,
      data: transaction.data.isNotEmpty ? transaction.data : null,
      value: _encodeQuantity(transaction.value),
    );
  }

  String? _encodeQuantity(BigInt value) {
    if (value == BigInt.zero) return null;
    return '0x${value.toRadixString(16)}';
  }
}

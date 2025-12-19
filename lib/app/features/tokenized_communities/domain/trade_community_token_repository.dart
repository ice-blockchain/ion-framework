// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/evm_tx_builder.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/ion_identity_transaction_api.dart';
import 'package:ion/app/features/tokenized_communities/data/trade_community_token_api.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_service.dart';
import 'package:ion/app/features/tokenized_communities/models/evm_transaction.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TradeCommunityTokenRepository {
  TradeCommunityTokenRepository({
    required this.txBuilder,
    required this.ionIdentity,
    required this.api,
  });

  final EvmTxBuilder txBuilder;
  final IonIdentityTransactionApi ionIdentity;
  final TradeCommunityTokenApi api;

  String? _cachedAbi;
  String? _cachedAddress;

  Future<void> _ensureConfigLoaded() async {
    if (_cachedAbi != null && _cachedAddress != null) return;
    _cachedAbi = await api.fetchBondingCurveAbi();
    _cachedAddress = await api.fetchBondingCurveAddress();
  }

  Future<CommunityToken?> fetchTokenInfo(String externalAddress) async {
    return api.fetchTokenInfo(externalAddress);
  }

  Future<String> fetchBondingCurveAddress() async {
    await _ensureConfigLoaded();
    return _cachedAddress!;
  }

  Future<PricingResponse> fetchPricing({
    required String externalAddress,
    required String type,
    required String amount,
  }) async {
    final pricing = await api.fetchPricing(externalAddress, type, amount);
    if (pricing == null) {
      throw TokenPricingNotFoundException(externalAddress);
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

  Future<TransactionResult> approve({
    required String walletId,
    required String tokenAddress,
    required BigInt amount,
    required BigInt maxFeePerGas,
    required BigInt maxPriorityFeePerGas,
    required UserActionSignerNew userActionSigner,
  }) async {
    await _ensureConfigLoaded();
    final approvalTx = await txBuilder.encodeApprove(
      token: tokenAddress,
      spender: _cachedAddress!,
      amount: amount,
    );

    final tx = _applyFees(
      approvalTx,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
    );

    return ionIdentity.signAndBroadcast(
      walletId: walletId,
      transaction: tx,
      userActionSigner: userActionSigner,
    );
  }

  Future<TransactionResult> swapCommunityToken({
    required String walletId,
    required List<int> fromTokenIdentifier,
    required List<int> toTokenIdentifier,
    required BigInt amountIn,
    required BigInt minReturn,
    required BigInt maxFeePerGas,
    required BigInt maxPriorityFeePerGas,
    required UserActionSignerNew userActionSigner,
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

    final tx = _applyFees(
      swapTx,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
    );

    return ionIdentity.signAndBroadcast(
      walletId: walletId,
      transaction: tx,
      userActionSigner: userActionSigner,
    );
  }

  EvmTransaction _applyFees(
    EvmTransaction transaction, {
    required BigInt maxFeePerGas,
    required BigInt maxPriorityFeePerGas,
  }) {
    return EvmTransaction(
      kind: transaction.kind,
      to: transaction.to,
      data: transaction.data,
      value: transaction.value,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
    );
  }
}

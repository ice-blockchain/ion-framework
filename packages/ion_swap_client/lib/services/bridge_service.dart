// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/exceptions/relay_exception.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/relay_quote.m.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:ion_swap_client/repositories/relay_api_repository.dart';
import 'package:ion_swap_client/utils/crypto_amount_converter.dart';
import 'package:ion_swap_client/utils/evm_tx_builder.dart';
import 'package:ion_swap_client/utils/hex_helper.dart';
import 'package:ion_swap_client/utils/ion_identity_transaction_api.dart';
import 'package:ion_swap_client/utils/swap_constants.dart';

class BridgeService {
  BridgeService({
    required RelayApiRepository relayApiRepository,
    required IonIdentityTransactionApi ionIdentityTransactionApi,
    required String relayEvmFeeAddress,
    required String relayAppFee,
    required EvmTxBuilder evmTxBuilder,
  })  : _relayApiRepository = relayApiRepository,
        _ionIdentityTransactionApi = ionIdentityTransactionApi,
        _relayEvmFeeAddress = relayEvmFeeAddress,
        _relayAppFee = relayAppFee,
        _evmTxBuilder = evmTxBuilder;
  final RelayApiRepository _relayApiRepository;
  final IonIdentityTransactionApi _ionIdentityTransactionApi;
  final String _relayEvmFeeAddress;
  final String _relayAppFee;
  final EvmTxBuilder _evmTxBuilder;

  Future<String?> tryToBridge({
    required SwapCoinParameters swapCoinData,
    required SwapQuoteInfo swapQuoteInfo,
    required IonSwapRequest ionSwapRequest,
  }) async {
    if (swapQuoteInfo.source == SwapQuoteInfoSource.relay) {
      final relayQuote = swapQuoteInfo.relayQuote;
      final relayDepositAmount = swapQuoteInfo.relayDepositAmount;
      if (relayQuote == null || relayDepositAmount == null) {
        throw const IonSwapException('Relay: Quote is required');
      }

      final approveStep = relayQuote.steps.firstWhereOrNull((step) => step.id == 'approve');
      if (approveStep != null) {
        final approveItem = approveStep.items.firstOrNull;
        if (approveItem == null) {
          throw const IonSwapException('Relay: Approve item is required');
        }

        final txObject = await _evmTxBuilder.encodeApproveTransaction(
          token: approveItem.data.to,
          data: approveItem.data.data,
        );

        await _ionIdentityTransactionApi.signAndBroadcast(
          walletId: ionSwapRequest.wallet.id,
          transaction: txObject,
          userActionSigner: ionSwapRequest.userActionSigner,
        );

        await Future<void>.delayed(SwapConstants.delayAfterApproveDuration);
      }

      final depositStep =
          relayQuote.steps.firstWhereOrNull((step) => step.id == 'deposit')?.items.first;
      if (depositStep == null) {
        throw const IonSwapException('Relay: Deposit step is required');
      }

      final sendableAsset = ionSwapRequest.sendableAsset;
      if (sendableAsset == null) {
        throw const IonSwapException('Lets Exchange: Sendable asset is required');
      }

      final hash = await _ionIdentityTransactionApi.signAndBroadcast(
        walletId: ionSwapRequest.wallet.id,
        userActionSigner: ionSwapRequest.userActionSigner,
        transaction: _evmTxBuilder.wrapTransactionBytes(
          bytes: HexHelper.hexToBytes(depositStep.data.data),
          to: depositStep.data.to,
          value: BigInt.parse(depositStep.data.value),
        ),
      );

      return hash;
    }

    return null;
  }

  Future<RelayQuote> getQuote(SwapCoinParameters swapCoinData) async {
    final sellAddress = swapCoinData.userSellAddress;
    final buyAddress = swapCoinData.userBuyAddress;
    if (sellAddress == null || buyAddress == null) {
      throw const IonSwapException('Sell or buy address is required');
    }

    final chains = await _relayApiRepository.getChains();
    final sellChainId = _getChainId(swapCoinData.sellCoin.network.id);
    final buyChainId = _getChainId(swapCoinData.buyCoin.network.id);
    final sellChain = chains.firstWhereOrNull(
      (chain) => chain.name.toLowerCase() == sellChainId.toLowerCase(),
    );
    final buyChain = chains.firstWhereOrNull(
      (chain) => chain.name.toLowerCase() == buyChainId.toLowerCase(),
    );

    if (sellChain == null || buyChain == null) {
      throw const CoinPairNotFoundException();
    }

    final swapAmount = toBlockchainUnits(
      swapCoinData.amount,
      swapCoinData.sellCoin.decimal,
    );
    try {
      final quote = await _relayApiRepository.getQuote(
        amount: swapAmount,
        user: sellAddress,
        recipient: buyAddress,
        originCurrency: _getTokenAddress(swapCoinData.sellCoin.contractAddress),
        destinationCurrency: _getTokenAddress(swapCoinData.buyCoin.contractAddress),
        originChainId: sellChain.id,
        destinationChainId: buyChain.id,
        appFeeRecipient: _relayEvmFeeAddress,
        appFee: BigInt.from(double.parse(_relayAppFee) * 100).toString(), // Convert to BPS
      );

      return quote;
    } on Exception catch (e) {
      if (e is DioException) {
        final response = e.response;
        final data = response?.data;

        if (data is Map<String, dynamic>) {
          final errorCode = data['errorCode'];

          if (errorCode is String) {
            throw RelayException.fromErrorCode(errorCode);
          }
        }
      }

      rethrow;
    }
  }

  String _getTokenAddress(String contractAddress) {
    return contractAddress.isEmpty ? _nativeTokenAddress : contractAddress;
  }

  String get _nativeTokenAddress => '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

  String _getChainId(String chainId) {
    final relayId = _parseIonChain(chainId).relayId;
    if (relayId != null) return relayId;

    return chainId;
  }

  _IonChainWithDifferentId _parseIonChain(String chainId) {
    final normalized = chainId.toLowerCase();

    if (normalized == SwapConstants.arbIonId.toLowerCase()) {
      return _IonChainWithDifferentId.arb;
    }

    if (normalized == SwapConstants.avalanceIonId.toLowerCase()) {
      return _IonChainWithDifferentId.avalanche;
    }

    if (normalized == SwapConstants.seiIonId.toLowerCase()) {
      return _IonChainWithDifferentId.sei;
    }

    return _IonChainWithDifferentId.unknown;
  }
}

enum _IonChainWithDifferentId {
  arb,
  avalanche,
  sei,
  unknown,
}

extension _IonChainX on _IonChainWithDifferentId {
  String? get relayId => switch (this) {
        _IonChainWithDifferentId.arb => SwapConstants.relayIonId,
        _IonChainWithDifferentId.avalanche => SwapConstants.relayAvalanceIonId,
        _IonChainWithDifferentId.sei => SwapConstants.relaySeiIonId,
        _IonChainWithDifferentId.unknown => null,
      };
}

// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/exceptions/okx_exceptions.dart';
import 'package:ion_swap_client/mixins/wait_for_confirmation_mixin.dart';
import 'package:ion_swap_client/models/chain_data.m.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/okx_api_response.m.dart';
import 'package:ion_swap_client/models/okx_fee_address.m.dart';
import 'package:ion_swap_client/models/okx_swap_quote_data_with_rpc.m.dart';
import 'package:ion_swap_client/models/swap_chain_data.m.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_data.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:ion_swap_client/repositories/chains_ids_repository.dart';
import 'package:ion_swap_client/repositories/relay_api_repository.dart';
import 'package:ion_swap_client/repositories/swap_okx_repository.dart';
import 'package:ion_swap_client/utils/crypto_amount_converter.dart';
import 'package:ion_swap_client/utils/evm_tx_builder.dart';
import 'package:ion_swap_client/utils/hex_helper.dart';
import 'package:ion_swap_client/utils/ion_identity_transaction_api.dart';
import 'package:ion_swap_client/utils/swap_constants.dart';

class DexService with WaitForConfirmationMixin {
  DexService({
    required SwapOkxRepository swapOkxRepository,
    required ChainsIdsRepository chainsIdsRepository,
    required EvmTxBuilder evmTxBuilder,
    required IonIdentityTransactionApi ionIdentityTransactionApi,
    required String defaultSwapPercentFee,
    required OkxFeeAddress okxFeeAddress,
    required RelayApiRepository relayApiRepository,
  })  : _swapOkxRepository = swapOkxRepository,
        _ionIdentityTransactionApi = ionIdentityTransactionApi,
        _chainsIdsRepository = chainsIdsRepository,
        _evmTxBuilder = evmTxBuilder,
        _defaultSwapPercentFee = defaultSwapPercentFee,
        _okxFeeAddress = okxFeeAddress,
        _relayApiRepository = relayApiRepository;

  final SwapOkxRepository _swapOkxRepository;
  final ChainsIdsRepository _chainsIdsRepository;
  final IonIdentityTransactionApi _ionIdentityTransactionApi;
  final EvmTxBuilder _evmTxBuilder;
  final String _defaultSwapPercentFee;
  final OkxFeeAddress _okxFeeAddress;

  // Need here to retrive rpc url for the sell blockchain
  final RelayApiRepository _relayApiRepository;

  // Returns transaction data if swap was successful, null otherwise
  Future<String?> tryToSwapDex({
    required SwapCoinParameters swapCoinData,
    required SwapQuoteInfo swapQuoteInfo,
    required Wallet wallet,
    required UserActionSignerNew userActionSigner,
    required IonSwapRequest ionSwapRequest,
  }) async {
    if (swapQuoteInfo.source == SwapQuoteInfoSource.okx) {
      final okxQuote = swapQuoteInfo.okxQuote;
      if (okxQuote == null) {
        throw const IonSwapException('OKX: Quote is required');
      }

      final sellTokenAddress = _getTokenAddressForOkx(swapCoinData.sellCoin.contractAddress);
      final buyTokenAddress = _getTokenAddressForOkx(swapCoinData.buyCoin.contractAddress);
      final amount = toBlockchainUnits(swapCoinData.amount, int.parse(okxQuote.fromToken.decimal));
      final bigIntAmount = BigInt.parse(amount);
      final isNativeToken = sellTokenAddress == _nativeTokenAddress;

      if (isNeedToApproveToken(okxQuote.chainIndex) && !isNativeToken) {
        final address = ionSwapRequest.wallet.address;
        if (address == null) {
          throw const IonSwapException('Wallet address is required for ion swap');
        }
        final approveTransactionResponse = await _swapOkxRepository.approveTransaction(
          chainIndex: okxQuote.chainIndex,
          tokenContractAddress: sellTokenAddress,
          amount: amount,
        );
        final approveTransactionData = _processOkxResponse(approveTransactionResponse);
        final approveTx = approveTransactionData.firstOrNull;

        if (approveTx == null) {
          throw const IonSwapException('OKX: No approve transaction data returned');
        }

        final allowance = await _safeCheckAllowance(
          sellTokenAddress,
          address,
          approveTx.dexContractAddress,
          wallet.id,
        );
        if (allowance < bigIntAmount) {
          final txHash = await _ionIdentityTransactionApi.signAndBroadcast(
            walletId: wallet.id,
            userActionSigner: userActionSigner,
            transaction: _evmTxBuilder.wrapTransactionBytes(
              bytes: HexHelper.hexToBytes(approveTx.data),
              to: sellTokenAddress,
              value: BigInt.zero,
            ),
          );

          final rcpUrl = swapQuoteInfo.sellBlockchainRcpUrl;
          if (rcpUrl == null) {
            await Future<void>.delayed(SwapConstants.delayAfterApproveDuration);
          } else {
            await waitForConfirmation(
              txHash: txHash,
              rpcUrl: rcpUrl,
            );

            final allowance2 = await _safeCheckAllowance(
              sellTokenAddress,
              address,
              approveTx.dexContractAddress,
              wallet.id,
            );

            if (allowance2 < bigIntAmount) {
              throw IonSwapException('Failed to approve token allowance, tx hash: $txHash');
            }
          }
        }
      }

      final userSellAddress = swapCoinData.userSellAddress;
      if (userSellAddress == null) {
        throw const IonSwapException('OKX: User sell address is required');
      }

      final swapResponse = await _swapOkxRepository.swap(
        amount: amount,
        chainIndex: okxQuote.chainIndex,
        toTokenAddress: buyTokenAddress,
        fromTokenAddress: sellTokenAddress,
        userWalletAddress: userSellAddress,
        slippagePercent: swapCoinData.slippage,
        feePercent: _defaultSwapPercentFee,
        fromTokenReferrerWalletAddress: _getFeeAddressByChainIndex(okxQuote.chainIndex),
      );

      final swapDataList = _processOkxResponse(swapResponse);
      if (swapDataList.isEmpty) {
        throw const IonSwapException('OKX: No swap data returned');
      }
      final tx = swapDataList.first.tx;
      final hash = await _ionIdentityTransactionApi.signAndBroadcast(
        walletId: wallet.id,
        userActionSigner: userActionSigner,
        transaction: _evmTxBuilder.wrapTransactionBytes(
          bytes: HexHelper.hexToBytes(tx.data),
          to: tx.to,
          value: BigInt.parse(tx.value),
        ),
      );

      return hash;
    }

    throw const IonSwapException('Failed to swap on Dex: Invalid quote source');
  }

  Future<BigInt> _safeCheckAllowance(
    String tokenAddress,
    String ownerAddress,
    String spenderAddress,
    String walletId,
  ) async {
    try {
      final response = await _ionIdentityTransactionApi.callFunction(
        walletId: walletId,
        request: CallFunctionRequest(
          contract: tokenAddress,
          abi: const CallFunctionAbi(
            name: 'allowance',
            inputs: [
              CallFunctionAbiParam(name: 'owner', type: 'address'),
              CallFunctionAbiParam(name: 'spender', type: 'address'),
            ],
            outputs: [
              CallFunctionAbiParam(name: '', type: 'uint256'),
            ],
          ),
          calldata: {
            'owner': ownerAddress,
            'spender': spenderAddress,
          },
        ),
      );

      if (response is BigInt) return response;
      if (response is int) return BigInt.from(response);
      if (response is String) return BigInt.tryParse(response) ?? BigInt.zero;
      return BigInt.zero;
    } catch (_) {
      return BigInt.zero;
    }
  }

  Future<SwapChainData?> _getOkxChain(String networkName) async {
    final results = await Future.wait([
      _chainsIdsRepository.getOkxChainsIds(),
      _swapOkxRepository.getSupportedChains(),
    ]);

    final supportedChainsIds = results[0] as List<ChainData>;
    final supportedChainsResponse = results[1] as OkxApiResponse<List<SwapChainData>>;

    final chainOkxData = supportedChainsIds.firstWhereOrNull(
      (chain) => chain.name.toLowerCase() == networkName.toLowerCase(),
    );
    final supportedChains = _processOkxResponse(supportedChainsResponse);
    final supportedChain = supportedChains.firstWhereOrNull(
      (chain) => chain.chainIndex == chainOkxData?.networkId,
    );

    return supportedChain;
  }

  SwapQuoteData _pickBestOkxQuote(List<SwapQuoteData> quotes) {
    final sortedQuotes = quotes.sortedByCompare<double>(
      (quote) => quote.priceForSellTokenInBuyToken,
      (a, b) => b.compareTo(a),
    );
    return sortedQuotes.first;
  }

  String _getTokenAddressForOkx(String contractAddress) {
    return contractAddress.isEmpty ? _nativeTokenAddress : contractAddress;
  }

  String get _nativeTokenAddress => '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

  T _processOkxResponse<T>(OkxApiResponse<T> response) {
    final responseCode = int.tryParse(response.code);
    if (responseCode == 0) {
      return response.data;
    }

    if (responseCode == null) {
      throw const IonSwapException('Failed to process OKX response');
    }

    throw OkxException.fromCode(responseCode);
  }

  Future<OkxSwapQuoteDataWithRpc?> getQuotes(SwapCoinParameters swapCoinData) async {
    final okxChain = await _getOkxChain(swapCoinData.sellCoin.network.name);
    final sellTokenAddress = _getTokenAddressForOkx(swapCoinData.sellCoin.contractAddress);
    final buyTokenAddress = _getTokenAddressForOkx(swapCoinData.buyCoin.contractAddress);

    if (okxChain != null) {
      final amount = toBlockchainUnits(swapCoinData.amount, swapCoinData.sellCoin.decimal);
      final quotesResponse = await _swapOkxRepository.getQuotes(
        amount: amount,
        chainIndex: okxChain.chainIndex,
        toTokenAddress: buyTokenAddress,
        fromTokenAddress: sellTokenAddress,
      );

      final quotes = _processOkxResponse(quotesResponse);

      if (quotes.isNotEmpty) {
        final quote = _pickBestOkxQuote(quotes);
        final rpcUrl = await _getRpcUrlForOkx(okxChain.chainIndex);

        return OkxSwapQuoteDataWithRpc(
          swapQuoteData: quote,
          rpcUrl: rpcUrl,
        );
      }
    }

    return null;
  }

  Future<String?> _getRpcUrlForOkx(int chainIndex) async {
    try {
      final response = await _relayApiRepository.getChains();

      final chain = response.firstWhereOrNull(
        (chain) => chain.id == chainIndex,
      );
      return chain?.httpRpcUrl;
    } on Object {
      return null;
    }
  }

  bool isNeedToApproveToken(String chainIndex) {
    final chainIndexInt = int.parse(chainIndex);
    return SwapConstants.okxEvmChainsIds.contains(chainIndexInt);
  }

  String _getFeeAddressByChainIndex(String chainIndex) {
    final chainIndexInt = int.parse(chainIndex);

    final feeAddress = switch (chainIndexInt) {
      43114 => _okxFeeAddress.avalanceAddress,
      42161 => _okxFeeAddress.arbitrumAddress,
      10 => _okxFeeAddress.optimistAddress,
      137 => _okxFeeAddress.polygonAddress,
      501 => _okxFeeAddress.solAddress,
      8453 => _okxFeeAddress.baseAddress,
      607 => _okxFeeAddress.tonAddress,
      195 => _okxFeeAddress.tronAddress,
      1 => _okxFeeAddress.ethAddress,
      56 => _okxFeeAddress.bnbAddress,
      _ => throw IonSwapException('Invalid chain index: $chainIndex'),
    };

    return feeAddress;
  }
}

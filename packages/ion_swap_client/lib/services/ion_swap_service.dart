// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:ion_swap_client/utils/evm_tx_builder.dart';
import 'package:ion_swap_client/utils/ion_identity_transaction_api.dart';
import 'package:ion_swap_client/utils/numb.dart';
import 'package:web3dart/web3dart.dart';

class IonSwapService {
  factory IonSwapService({
    required IONSwapConfig config,
    required Web3Client web3client,
    required EvmTxBuilder evmTxBuilder,
    required IonIdentityTransactionApi ionIdentityClient,
  }) {
    return IonSwapService._(
      config: config,
      web3client: web3client,
      evmTxBuilder: evmTxBuilder,
      ionIdentityClient: ionIdentityClient,
    );
  }

  IonSwapService._({
    required IONSwapConfig config,
    required Web3Client web3client,
    required EvmTxBuilder evmTxBuilder,
    required IonIdentityTransactionApi ionIdentityClient,
  })  : _ionIdentityClient = ionIdentityClient,
        _web3client = web3client,
        _evmTxBuilder = evmTxBuilder,
        _ionSwapAddress = EthereumAddress.fromHex(config.ionSwapContractAddress),
        _iceTokenAddress = EthereumAddress.fromHex(config.iceBscTokenAddress),
        _ionTokenAddress = EthereumAddress.fromHex(config.ionBscTokenAddress);

  final Web3Client _web3client;
  final EthereumAddress _ionSwapAddress;
  final EthereumAddress _iceTokenAddress;
  final EthereumAddress _ionTokenAddress;
  final EvmTxBuilder _evmTxBuilder;
  final IonIdentityTransactionApi _ionIdentityClient;

  Future<SwapQuoteInfo> getQuote({
    required SwapCoinParameters swapCoinData,
  }) async {
    return SwapQuoteInfo(
      type: SwapQuoteInfoType.bridge,
      priceForSellTokenInBuyToken: 1,
      source: SwapQuoteInfoSource.ionOnchain,
    );
  }

  Future<String> swapCoins({
    required SwapCoinParameters swapCoinData,
    required IonSwapRequest request,
  }) async {
    final direction = _getDirection(swapCoinData);
    final sellDecimals = await _fetchDecimals(direction.sellToken);

    final amountIn = parseAmount(
      swapCoinData.amount,
      sellDecimals,
    );

    if (amountIn == BigInt.zero) {
      throw const IonSwapException('Swap amount must be greater than zero');
    }

    final owner = _toEthereumAddress(request.wallet.address);

    await _ensureAllowance(
      owner: owner,
      token: direction.sellToken,
      amount: amountIn,
      request: request,
      tokenDecimals: swapCoinData.sellCoin.decimal,
    );


    final txHash = await _swap(
      direction: direction,
      amountIn: amountIn,
      request: request,
    );

    if (!_isBscTxHash(txHash)) {
      throw const IonSwapException('Swap failed on-chain');
    }

    await _waitForConfirmation(txHash);

    return txHash;
  }

  Future<String> _swap({
    required _SwapDirection direction,
    required BigInt amountIn,
    required IonSwapRequest request,
  }) async {
    final swapFunction = direction.isIceToIon ? 'swapTokens' : 'swapTokensBack';
    final function = _ionSwapContract.function(swapFunction);

    final data = function.encodeCall(
      [
        amountIn,
      ],
    );

    final swapTx = _evmTxBuilder.wrapTransactionBytes(
      bytes: data,
      value: BigInt.zero,
      to: _ionSwapAddress.hex,
    );

    final tx = _applyFees(
      swapTx,
      maxFeePerGas: BigInt.from(20000000000),
      maxPriorityFeePerGas: BigInt.from(1000000000),
    );

    return _signAndBroadcast(
      request: request,
      transaction: tx,
    );
  }

  Future<TransactionReceipt> _waitForConfirmation(
    String txHash, {
    int maxTries = 40,
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    for (var i = 0; i < maxTries; i++) {
      final receipt = await _web3client.getTransactionReceipt(txHash);
      if (receipt != null) {
        if (receipt.status ?? false) return receipt;
        throw const IonSwapException('Swap failed on-chain');
      }
      await Future<void>.delayed(pollInterval);
    }
    throw const IonSwapException('Timed out waiting for confirmation');
  }

  bool _isBscTxHash(String txHash) {
    return txHash.startsWith('0x') && txHash.length == 66;
  }

  bool isSupportedPair(SwapCoinParameters swapCoinData) {
    final isBsc = swapCoinData.sellCoin.network.id.toLowerCase() == _bscNetworkId &&
        swapCoinData.buyCoin.network.id.toLowerCase() == _bscNetworkId;

    if (!isBsc) {
      return false;
    }

    return _matchesAddress(swapCoinData.sellCoin.contractAddress, _iceTokenAddress) &&
            _matchesAddress(swapCoinData.buyCoin.contractAddress, _ionTokenAddress) ||
        _matchesAddress(swapCoinData.sellCoin.contractAddress, _ionTokenAddress) &&
            _matchesAddress(swapCoinData.buyCoin.contractAddress, _iceTokenAddress);
  }

  Future<void> _ensureAllowance({
    required EthereumAddress owner,
    required EthereumAddress token,
    required BigInt amount,
    required IonSwapRequest request,
    required int tokenDecimals,
  }) async {
    final allowance = await _evmTxBuilder.allowance(
      token: token.hex,
      owner: owner.hex,
      spender: _ionSwapAddress.hex,
    );

    if (allowance < amount) {
      // Approve 1 Trillion tokens (10^12) with token decimals
      final trillionAmount = BigInt.from(10).pow(12 + tokenDecimals);

      final approvalTx = await _evmTxBuilder.encodeApprove(
        token: token.hex,
        spender: _ionSwapAddress.hex,
        amount: trillionAmount,
      );

      final tx = _applyFees(
        approvalTx,
        maxFeePerGas: BigInt.from(20000000000),
        maxPriorityFeePerGas: BigInt.from(1000000000),
      );

      await _signAndBroadcast(
        request: request,
        transaction: tx,
      );

      await Future<void>.delayed(const Duration(seconds: 3));

      final allowance2 = await _evmTxBuilder.allowance(
        token: token.hex,
        owner: owner.hex,
        spender: _ionSwapAddress.hex,
      );

      if (allowance2 < amount) {
        throw const IonSwapException('Failed to approve token allowance');
      }
    }
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

  Future<BigInt> _fetchDecimals(EthereumAddress token) async {
    final decimalsFunction = _erc20ContractFor(token).function('decimals');

    final result = await _web3client.call(
      contract: _erc20ContractFor(token),
      function: decimalsFunction,
      params: const [],
    );

    if (result.isEmpty || result.first is! BigInt) {
      throw const IonSwapException('Failed to fetch token decimals');
    }

    return result.first as BigInt;
  }

  _SwapDirection _getDirection(SwapCoinParameters swapCoinData) {
    final isIceToIon = _matchesAddress(swapCoinData.sellCoin.contractAddress, _iceTokenAddress) &&
        _matchesAddress(swapCoinData.buyCoin.contractAddress, _ionTokenAddress);

    final isIonToIce = _matchesAddress(swapCoinData.sellCoin.contractAddress, _ionTokenAddress) &&
        _matchesAddress(swapCoinData.buyCoin.contractAddress, _iceTokenAddress);

    if (!isIceToIon && !isIonToIce) {
      throw const IonSwapException('Unsupported token pair for on-chain ION swap');
    }

    return _SwapDirection(
      isIceToIon: isIceToIon,
      sellToken: isIceToIon ? _iceTokenAddress : _ionTokenAddress,
      buyToken: isIceToIon ? _ionTokenAddress : _iceTokenAddress,
    );
  }

  bool _matchesAddress(String candidate, EthereumAddress expected) {
    return candidate.toLowerCase() == expected.hex.toLowerCase();
  }

  EthereumAddress _toEthereumAddress(String? address) {
    if (address == null || address.isEmpty) {
      throw const IonSwapException('Wallet address is required for ion swap');
    }

    return EthereumAddress.fromHex(address);
  }

  Future<String> _signAndBroadcast({
    required IonSwapRequest request,
    required EvmTransaction transaction,
  }) async {
    return _ionIdentityClient.signAndBroadcast(
      walletId: request.wallet.id,
      transaction: transaction,
      userActionSigner: request.userActionSigner,
    );
  }

  DeployedContract _erc20ContractFor(EthereumAddress address) => DeployedContract(
        _erc20AbiParsed,
        address,
      );

  DeployedContract get _ionSwapContract => DeployedContract(
        _ionSwapAbiParsed,
        _ionSwapAddress,
      );

  static final ContractAbi _ionSwapAbiParsed = ContractAbi.fromJson(_ionSwapAbi, 'IONSwap');

  static const _ionSwapAbi = '''
[
  {"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"swapTokens","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"swapTokensBack","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"getPooledAmountOut","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"getOtherAmountOut","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}
]
''';

  static const _erc20Abi = '''
[
  {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},
  {"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"type":"function"},
  {"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"type":"function"}
]
''';

  static final ContractAbi _erc20AbiParsed = ContractAbi.fromJson(_erc20Abi, 'ERC20');

  static const _bscNetworkId = 'bsc';
}

class _SwapDirection {
  _SwapDirection({
    required this.isIceToIon,
    required this.sellToken,
    required this.buyToken,
  });

  final bool isIceToIon;
  final EthereumAddress sellToken;
  final EthereumAddress buyToken;
}

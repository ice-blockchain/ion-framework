// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:convert/convert.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:web3dart/web3dart.dart';

class IonSwapService {
  factory IonSwapService({
    required IONSwapConfig config,
    required Web3Client web3client,
  }) {
    return IonSwapService._(
      config: config,
      web3client: web3client,
    );
  }

  IonSwapService._({
    required IONSwapConfig config,
    required Web3Client web3client,
  })  : _web3client = web3client,
        _ionSwapAddress = EthereumAddress.fromHex(config.ionSwapContractAddress),
        _iceTokenAddress = EthereumAddress.fromHex(config.iceBscTokenAddress),
        _ionTokenAddress = EthereumAddress.fromHex(config.ionBscTokenAddress);

  final Web3Client _web3client;
  final EthereumAddress _ionSwapAddress;
  final EthereumAddress _iceTokenAddress;
  final EthereumAddress _ionTokenAddress;

  Future<SwapQuoteInfo> getQuote({
    required SwapCoinParameters swapCoinData,
  }) async {
    return SwapQuoteInfo(
      type: SwapQuoteInfoType.cexOrDex,
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

    final amountIn = _parseAmount(
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
    );

    final swapTx = await _buildSwapTransaction(
      direction: direction,
      amountIn: amountIn,
      request: request,
    );

    return swapTx;
  }

  bool isSupportedPair(SwapCoinParameters swapCoinData) {
    final isBsc = swapCoinData.sellNetworkId.toLowerCase() == 'bsc' &&
        swapCoinData.buyNetworkId.toLowerCase() == 'bsc';

    if (!isBsc) {
      return false;
    }

    return _matchesAddress(swapCoinData.sellCoinContractAddress, _iceTokenAddress) &&
            _matchesAddress(swapCoinData.buyCoinContractAddress, _ionTokenAddress) ||
        _matchesAddress(swapCoinData.sellCoinContractAddress, _ionTokenAddress) &&
            _matchesAddress(swapCoinData.buyCoinContractAddress, _iceTokenAddress);
  }

  Future<String> _buildSwapTransaction({
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

    final tx = EvmBroadcastRequest.transactionJson(
      transaction: EvmTransactionJson(
        to: _ionSwapAddress.hexEip55,
        data: hex.encode(data).with0x,
        value: '0x0',
        maxFeePerGas: _encodeQuantity(request.maxFeePerGas),
        maxPriorityFeePerGas: _encodeQuantity(request.maxPriorityFeePerGas),
      ),
    );

    return _signAndBroadcast(
      request: request,
      broadcastRequest: tx,
    );
  }

  Future<void> _ensureAllowance({
    required EthereumAddress owner,
    required EthereumAddress token,
    required BigInt amount,
    required IonSwapRequest request,
  }) async {
    final allowance = await _getAllowance(owner: owner, token: token);

    if (allowance >= amount) {
      return;
    }

    final approveFunction = _erc20ContractFor(token).function('approve');
    final data = approveFunction.encodeCall(
      [
        _ionSwapAddress,
        amount,
      ],
    );

    final tx = EvmBroadcastRequest.transactionJson(
      transaction: EvmTransactionJson(
        to: token.hexEip55,
        data: hex.encode(data).with0x,
        value: '0x0',
        maxFeePerGas: _encodeQuantity(request.maxFeePerGas),
        maxPriorityFeePerGas: _encodeQuantity(request.maxPriorityFeePerGas),
      ),
    );

    await _signAndBroadcast(
      request: request,
      broadcastRequest: tx,
    );
  }

  Future<BigInt> _getAllowance({
    required EthereumAddress owner,
    required EthereumAddress token,
  }) async {
    final allowanceFunction = _erc20ContractFor(token).function('allowance');
    final result = await _web3client.call(
      contract: _erc20ContractFor(token),
      function: allowanceFunction,
      params: [owner, _ionSwapAddress],
    );

    if (result.isEmpty || result.first is! BigInt) {
      throw const IonSwapException('Invalid allowance response');
    }

    return result.first as BigInt;
  }

  Future<int> _fetchDecimals(EthereumAddress token) async {
    final decimalsFunction = _erc20ContractFor(token).function('decimals');

    final result = await _web3client.call(
      contract: _erc20ContractFor(token),
      function: decimalsFunction,
      params: const [],
    );

    if (result.isEmpty || result.first is! int) {
      throw const IonSwapException('Failed to fetch token decimals');
    }

    return result.first as int;
  }

  _SwapDirection _getDirection(SwapCoinParameters swapCoinData) {
    final isIceToIon = _matchesAddress(swapCoinData.sellCoinContractAddress, _iceTokenAddress) &&
        _matchesAddress(swapCoinData.buyCoinContractAddress, _ionTokenAddress);

    final isIonToIce = _matchesAddress(swapCoinData.sellCoinContractAddress, _ionTokenAddress) &&
        _matchesAddress(swapCoinData.buyCoinContractAddress, _iceTokenAddress);

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

  BigInt _parseAmount(String amount, int decimals) {
    final sanitized = amount.trim();
    if (sanitized.isEmpty) {
      throw const IonSwapException('Invalid amount format');
    }

    final parts = sanitized.split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    final fraction = parts.length > 1 ? parts[1] : '';

    final fractionPadded = fraction.padRight(decimals, '0');
    final fractionCropped = fractionPadded.substring(0, decimals);

    final normalized = '$whole$fractionCropped';

    return BigInt.parse(normalized);
  }

  String _encodeQuantity(BigInt value) {
    if (value == BigInt.zero) {
      return '0x0';
    }
    return '0x${value.toRadixString(16)}';
  }

  EthereumAddress _toEthereumAddress(String? address) {
    if (address == null || address.isEmpty) {
      throw const IonSwapException('Wallet address is required for ion swap');
    }

    return EthereumAddress.fromHex(address);
  }

  Future<String> _signAndBroadcast({
    required IonSwapRequest request,
    required EvmBroadcastRequest broadcastRequest,
  }) async {
    final response = await request.identityClient.wallets.signAndBroadcast(
      request.wallet,
      broadcastRequest,
      request.userActionSigner,
    );

    return _extractTransactionIdentifier(response);
  }

  String _extractTransactionIdentifier(Map<String, dynamic> response) {
    final txHash = response['txHash'] as String?;
    final id = response['id'] as String?;
    final transferId = response['transferId'] as String?;
    return txHash ??
        id ??
        transferId ??
        (throw const IonSwapException('Ion Identity response did not include a transaction id'));
  }

  DeployedContract get _ionSwapContract => DeployedContract(
        _ionSwapAbiParsed,
        _ionSwapAddress,
      );

  DeployedContract _erc20ContractFor(EthereumAddress address) => DeployedContract(
        _erc20AbiParsed,
        address,
      );

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

  static final ContractAbi _ionSwapAbiParsed = ContractAbi.fromJson(_ionSwapAbi, 'IONSwap');
  static final ContractAbi _erc20AbiParsed = ContractAbi.fromJson(_erc20Abi, 'ERC20');
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

extension on String {
  String get with0x => startsWith('0x') ? this : '0x$this';
}

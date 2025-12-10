// SPDX-License-Identifier: ice License 1.0

import 'dart:typed_data';

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:ion_swap_client/utils/evm_tx_builder.dart';
import 'package:ion_swap_client/utils/ion_identity_transaction_api.dart';
import 'package:ion_swap_client/utils/numb.dart';
import 'package:tonutils/dataformat.dart';
import 'package:web3dart/web3dart.dart';

/// Bridges wION on BSC to native ION on the ION chain by burning wION.
///
/// The flow follows the reference implementation documented at:
/// https://github.com/ice-blockchain/bridge/blob/ion-mainnet/documentation/integration-flow.md
class IonBscToIonBridgeService {
  IonBscToIonBridgeService({
    required IONSwapConfig config,
    required Web3Client web3client,
    required EvmTxBuilder evmTxBuilder,
    required IonIdentityTransactionApi ionIdentityClient,
  })  : _web3client = web3client,
        _evmTxBuilder = evmTxBuilder,
        _ionIdentityClient = ionIdentityClient,
        _wIonTokenAddress = EthereumAddress.fromHex(config.ionBscTokenAddress),
        _ionBridgeRouterAddress = EthereumAddress.fromHex(config.ionBridgeRouterContractAddress);

  final Web3Client _web3client;
  final EvmTxBuilder _evmTxBuilder;
  final IonIdentityTransactionApi _ionIdentityClient;
  final EthereumAddress _wIonTokenAddress;
  final EthereumAddress _ionBridgeRouterAddress;

  Future<SwapQuoteInfo> getQuote({
    required SwapCoinParameters swapCoinData,
  }) async {
    if (!isSupportedPair(swapCoinData)) {
      throw const IonSwapException('Unsupported token pair for ION BSC → ION bridge');
    }

    return SwapQuoteInfo(
      type: SwapQuoteInfoType.bridge,
      priceForSellTokenInBuyToken: 1,
      source: SwapQuoteInfoSource.ionOnchain,
    );
  }

  Future<String> bridgeToIon({
    required SwapCoinParameters swapCoinData,
    required IonSwapRequest request,
  }) async {
    if (!isSupportedPair(swapCoinData)) {
      throw const IonSwapException('Unsupported token pair for ION BSC → ION bridge');
    }

    final ionDestination = _parseIonAddress(swapCoinData.userBuyAddress);
    final tokenDecimals = await _fetchDecimals(_wIonTokenAddress);

    final amountIn = parseAmount(
      swapCoinData.amount,
      tokenDecimals,
    );

    if (amountIn == BigInt.zero) {
      throw const IonSwapException('Bridge amount must be greater than zero');
    }

    final owner = _toEthereumAddress(request.wallet.address);

    await _ensureAllowance(
      owner: owner,
      token: _wIonTokenAddress,
      amount: amountIn,
      request: request,
      tokenDecimals: swapCoinData.sellCoin.decimal,
    );

    final burnFunction = _ionBridgeRouterContract.function('burn');
    final data = burnFunction.encodeCall(
      [
        amountIn,
        [
          BigInt.from(ionDestination.workchain),
          ionDestination.addressHash,
        ],
      ],
    );

    final burnTx = _evmTxBuilder.wrapTransactionBytes(
      bytes: data,
      value: BigInt.zero,
      to: _ionBridgeRouterAddress.hex,
    );

    final txWithFees = _applyFees(
      burnTx,
      maxFeePerGas: BigInt.from(20000000000),
      maxPriorityFeePerGas: BigInt.from(1000000000),
    );

    final txHash = await _signAndBroadcast(
      request: request,
      transaction: txWithFees,
    );

    if (!_isBscTxHash(txHash)) {
      throw const IonSwapException('Bridge burn failed on-chain');
    }

    await _waitForConfirmation(txHash);

    return txHash;
  }

  bool isSupportedPair(SwapCoinParameters swapCoinData) {
    final isBscSell = swapCoinData.sellCoin.network.id.toLowerCase() == _bscNetworkId;
    final isIonTarget = swapCoinData.buyCoin.network.id.toLowerCase().contains(_ionNetworkId);

    if (!isBscSell || !isIonTarget) {
      return false;
    }

    final matchesIonBscToken =
        swapCoinData.sellCoin.contractAddress.toLowerCase() == _wIonTokenAddress.hex.toLowerCase();

    return matchesIonBscToken;
  }

  _IonTonAddress _parseIonAddress(String? address) {
    if (address == null) {
      throw const IonSwapException('ION address is required for bridge');
    }

    final addressTon = InternalAddress.parse(address);

    return _IonTonAddress(
      workchain: addressTon.workChain.toInt(),
      addressHash: addressTon.hash,
    );
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
      spender: _ionBridgeRouterAddress.hex,
    );

    if (allowance < amount) {
      // Approve 1 Trillion tokens (10^12) with token decimals
      final trillionAmount = BigInt.from(10).pow(12 + tokenDecimals);

      final approvalTx = await _evmTxBuilder.encodeApprove(
        token: token.hex,
        spender: _ionBridgeRouterAddress.hex,
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
        spender: _ionBridgeRouterAddress.hex,
      );

      if (allowance2 < amount) {
        throw const IonSwapException('Failed to approve token allowance');
      }
    }
  }

  EthereumAddress _toEthereumAddress(String? address) {
    if (address == null || address.isEmpty) {
      throw const IonSwapException('Wallet address is required for bridge');
    }

    return EthereumAddress.fromHex(address);
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

  Future<TransactionReceipt> _waitForConfirmation(
    String txHash, {
    int maxTries = 20,
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    for (var i = 0; i < maxTries; i++) {
      final receipt = await _web3client.getTransactionReceipt(txHash);
      if (receipt != null) {
        if (receipt.status ?? false) return receipt;
        throw const IonSwapException('Bridge burn failed on-chain');
      }
      await Future<void>.delayed(pollInterval);
    }
    throw const IonSwapException('Timed out waiting for confirmation');
  }

  bool _isBscTxHash(String txHash) {
    return txHash.startsWith('0x') && txHash.length == 66;
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

  Future<String> _signAndBroadcast({
    required IonSwapRequest request,
    required EvmTransaction transaction,
  }) async {
    final userActionSigner = request.userActionSigner;
    if (userActionSigner == null) {
      throw const IonSwapException('User action signer is required for ion bridge');
    }

    return _ionIdentityClient.signAndBroadcast(
      walletId: request.wallet.id,
      transaction: transaction,
      userActionSigner: userActionSigner,
    );
  }

  DeployedContract _erc20ContractFor(EthereumAddress address) => DeployedContract(
        _erc20AbiParsed,
        address,
      );

  DeployedContract get _ionBridgeRouterContract => DeployedContract(
        _ionBridgeRouterAbiParsed,
        _ionBridgeRouterAddress,
      );

  static final ContractAbi _ionBridgeRouterAbiParsed =
      ContractAbi.fromJson(_ionBridgeRouterAbi, 'IONBridgeRouter');

  static const _ionBridgeRouterAbi = '''
[
  {
    "inputs": [
      {"internalType":"uint256","name":"amount","type":"uint256"},
      {"components":[{"internalType":"int8","name":"workchain","type":"int8"},{"internalType":"bytes32","name":"address_hash","type":"bytes32"}],"internalType":"struct TonAddress","name":"addr","type":"tuple"}
    ],
    "name":"burn",
    "outputs":[],
    "stateMutability":"nonpayable",
    "type":"function"
  }
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
  static const _ionNetworkId = 'ion';
}

class _IonTonAddress {
  _IonTonAddress({
    required this.workchain,
    required this.addressHash,
  });

  final int workchain;
  final Uint8List addressHash;
}

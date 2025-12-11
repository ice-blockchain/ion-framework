// SPDX-License-Identifier: ice License 1.0

import 'dart:typed_data';

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/utils/evm_tx_builder.dart';
import 'package:ion_swap_client/utils/ion_identity_transaction_api.dart';
import 'package:web3dart/web3dart.dart';

class IonBridgeService {
  factory IonBridgeService({
    required IONSwapConfig config,
    required Web3Client web3client,
    required EvmTxBuilder evmTxBuilder,
    required IonIdentityTransactionApi ionIdentityClient,
  }) {
    if (config.ionBridgeRouterAddress.isEmpty) {
      throw const IonSwapException('ION bridge router address is required');
    }

    return IonBridgeService._(
      routerAddress: EthereumAddress.fromHex(config.ionBridgeRouterAddress),
      ionBscTokenAddress: EthereumAddress.fromHex(config.ionBscTokenAddress),
      web3client: web3client,
      evmTxBuilder: evmTxBuilder,
      ionIdentityClient: ionIdentityClient,
    );
  }

  IonBridgeService._({
    required Web3Client web3client,
    required EvmTxBuilder evmTxBuilder,
    required IonIdentityTransactionApi ionIdentityClient,
    required EthereumAddress routerAddress,
    required EthereumAddress ionBscTokenAddress,
  })  : _web3client = web3client,
        _evmTxBuilder = evmTxBuilder,
        _ionIdentityClient = ionIdentityClient,
        _routerAddress = routerAddress,
        _ionTokenAddress = ionBscTokenAddress;

  final Web3Client _web3client;
  final EvmTxBuilder _evmTxBuilder;
  final IonIdentityTransactionApi _ionIdentityClient;
  final EthereumAddress _routerAddress;
  final EthereumAddress _ionTokenAddress;

  /// Performs BSC -> ION bridge by burning wrapped ION on BSC.
  Future<String> bridgeBscToIon({
    required SwapCoinParameters swapCoinData,
    required TonAddress destination,
    required IonSwapRequest request,
  }) async {
    _assertBscToIonSwap(swapCoinData);

    final decimals = await _fetchDecimals(_ionTokenAddress);
    final amountIn = _parseAmount(swapCoinData.amount, decimals);

    if (amountIn == BigInt.zero) {
      throw const IonSwapException('Bridge amount must be greater than zero');
    }

    final owner = _toEthereumAddress(request.wallet.address);

    await _ensureAllowance(
      owner: owner,
      token: _ionTokenAddress,
      amount: amountIn,
      request: request,
      tokenDecimals: decimals.toInt(),
    );

    return _burn(
      amountIn: amountIn,
      destination: destination,
      request: request,
    );
  }

  bool isSupportedBscToIon(SwapCoinParameters swapCoinData) {
    final isBsc = swapCoinData.sellNetworkId.toLowerCase() == 'bsc';
    final isBscToken = _matchesAddress(swapCoinData.sellCoinContractAddress, _ionTokenAddress);
    return isBsc && isBscToken;
  }

  Future<String> _burn({
    required BigInt amountIn,
    required TonAddress destination,
    required IonSwapRequest request,
  }) async {
    final burnFunction = _bridgeRouterContract.function('burn');
    final data = burnFunction.encodeCall(
      [
        amountIn,
        [
          BigInt.from(destination.workchain),
          destination.addressHash,
        ],
      ],
    );

    final burnTx = _evmTxBuilder.wrapTransactionBytes(
      bytes: data,
      value: BigInt.zero,
      to: _routerAddress.hex,
    );

    final tx = _applyFees(
      burnTx,
      request: request,
    );

    return _signAndBroadcast(
      request: request,
      transaction: tx,
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
      spender: _routerAddress.hex,
    );

    if (allowance < amount) {
      final trillionAmount = BigInt.from(10).pow(12 + tokenDecimals);

      final approvalTx = await _evmTxBuilder.encodeApprove(
        token: token.hex,
        spender: _routerAddress.hex,
        amount: trillionAmount,
      );

      final tx = _applyFees(
        approvalTx,
        request: request,
      );

      await _signAndBroadcast(
        request: request,
        transaction: tx,
      );
    }
  }

  EvmTransaction _applyFees(
    EvmTransaction transaction, {
    required IonSwapRequest request,
  }) {
    return EvmTransaction(
      kind: transaction.kind,
      to: transaction.to,
      data: transaction.data,
      value: transaction.value,
      maxFeePerGas: request.maxFeePerGas,
      maxPriorityFeePerGas: request.maxPriorityFeePerGas,
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

  void _assertBscToIonSwap(SwapCoinParameters swapCoinData) {
    if (!isSupportedBscToIon(swapCoinData)) {
      throw const IonSwapException('Unsupported token pair for ION bridge');
    }
  }

  bool _matchesAddress(String candidate, EthereumAddress expected) {
    return candidate.toLowerCase() == expected.hex.toLowerCase();
  }

  BigInt _parseAmount(String amount, BigInt decimals) {
    final sanitized = amount.trim();
    if (sanitized.isEmpty) {
      throw const IonSwapException('Invalid amount format');
    }

    final parts = sanitized.split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    final fraction = parts.length > 1 ? parts[1] : '';

    final fractionPadded = fraction.padRight(decimals.toInt(), '0');
    final fractionCropped = fractionPadded.substring(0, decimals.toInt());

    final normalized = '$whole$fractionCropped';

    return BigInt.parse(normalized);
  }

  EthereumAddress _toEthereumAddress(String? address) {
    if (address == null || address.isEmpty) {
      throw const IonSwapException('Wallet address is required for ION bridge');
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

  DeployedContract get _bridgeRouterContract => DeployedContract(
        _ionBridgeRouterAbiParsed,
        _routerAddress,
      );

  static TonAddress parseTonAddress(String address) {
    final normalized = address.trim();
    if (normalized.isEmpty) {
      throw const IonSwapException('TON address is required');
    }

    final parts = normalized.split(':');
    if (parts.length != 2) {
      throw const IonSwapException('TON address must be in <workchain>:<hash> format');
    }

    final workchain = int.tryParse(parts.first);
    if (workchain == null) {
      throw const IonSwapException('TON workchain must be numeric');
    }

    return TonAddress.fromHex(
      workchain: workchain,
      addressHashHex: parts[1],
    );
  }

  static final ContractAbi _erc20AbiParsed = ContractAbi.fromJson(_erc20Abi, 'ERC20');

  static const _erc20Abi = '''
[
  {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},
  {"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"type":"function"},
  {"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"type":"function"}
]
''';

  static final ContractAbi _ionBridgeRouterAbiParsed = ContractAbi.fromJson(_ionBridgeRouterAbi, 'IONBridgeRouter');

  static const _ionBridgeRouterAbi = '''
[
  {"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"},{"components":[{"internalType":"int8","name":"workchain","type":"int8"},{"internalType":"bytes32","name":"address_hash","type":"bytes32"}],"internalType":"struct IONBridgeRouter.TonAddress","name":"addr","type":"tuple"}],"name":"burn","outputs":[],"stateMutability":"nonpayable","type":"function"}
]
''';
}

class TonAddress {
  TonAddress({
    required this.workchain,
    required this.addressHash,
  }) {
    if (addressHash.length != _bytes32Length) {
      throw const IonSwapException('TON address hash must be 32 bytes long');
    }
  }

  factory TonAddress.fromHex({
    required int workchain,
    required String addressHashHex,
  }) {
    final normalized = addressHashHex.trim();
    if (normalized.isEmpty) {
      throw const IonSwapException('TON address hash is required');
    }

    final bytes = _decodeHash(normalized);
    return TonAddress(
      workchain: workchain,
      addressHash: bytes,
    );
  }

  final int workchain;
  final Uint8List addressHash;

  static const _bytes32Length = 32;
}

Uint8List _decodeHash(String value) {
  final hex = value.startsWith('0x') ? value.substring(2) : value;

  if (hex.length > _bytes32HexLength) {
    throw const IonSwapException('TON address hash exceeds 32 bytes');
  }

  final padded = hex.padLeft(_bytes32HexLength, '0');
  final result = Uint8List(_bytes32Length);

  for (var i = 0; i < _bytes32Length; i++) {
    final index = i * 2;
    result[i] = int.parse(padded.substring(index, index + 2), radix: 16);
  }

  return result;
}

const _bytes32Length = 32;
const _bytes32HexLength = _bytes32Length * 2;

// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:ion/app/features/tokenized_communities/blockchain/evm_contract_providers.dart';
import 'package:ion/app/features/tokenized_communities/models/evm_transaction.dart';
import 'package:ion/app/utils/hex_encoding.dart';
import 'package:web3dart/web3dart.dart';

class EvmTxBuilder {
  EvmTxBuilder({
    required this.contracts,
    required this.web3Client,
  });

  final EvmContractProviders contracts;
  final Web3Client web3Client;
  BondingCurveContract? _cachedBondingCurve;

  Future<EvmTransaction> encodeApprove({
    required String token,
    required String spender,
    required BigInt amount,
  }) async {
    final abiList = await contracts.loadErc20Abi();
    final contract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(abiList), 'ERC20'),
      EthereumAddress.fromHex(token),
    );
    final function = contract.function('approve');
    final data = function.encodeCall([
      EthereumAddress.fromHex(spender),
      amount,
    ]);

    return _wrapTransaction(
      to: token,
      data: bytesToHex(data),
      value: BigInt.zero,
    );
  }

  Future<EvmTransaction> encodeSwap({
    required List<int> fromTokenIdentifier,
    required List<int> toTokenIdentifier,
    required BigInt amountIn,
    required BigInt minReturn,
    required String bondingCurveAbi,
    required String bondingCurveAddress,
  }) async {
    final contract = await _ensureBondingCurveContract(
      abi: bondingCurveAbi,
      address: bondingCurveAddress,
    );

    final deployedContract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(contract.abi), 'BondingCurve'),
      EthereumAddress.fromHex(contract.address),
    );

    final function = deployedContract.function('swap');
    final data = function.encodeCall([
      Uint8List.fromList(fromTokenIdentifier),
      Uint8List.fromList(toTokenIdentifier),
      amountIn,
      minReturn,
    ]);

    return _wrapTransaction(
      to: bondingCurveAddress,
      data: bytesToHex(data),
      value: BigInt.zero,
    );
  }

  Future<BigInt> quote({
    required List<int> fromTokenIdentifier,
    required List<int> toTokenIdentifier,
    required BigInt amountIn,
    required String bondingCurveAbi,
    required String bondingCurveAddress,
  }) async {
    final contract = await _ensureBondingCurveContract(
      abi: bondingCurveAbi,
      address: bondingCurveAddress,
    );

    final deployedContract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(contract.abi), 'BondingCurve'),
      EthereumAddress.fromHex(contract.address),
    );

    final function = deployedContract.function('quoteBuyOut');

    final result = await web3Client.call(
      contract: deployedContract,
      function: function,
      params: [
        Uint8List.fromList(fromTokenIdentifier),
        Uint8List.fromList(toTokenIdentifier),
        amountIn,
      ],
    );

    return result.first as BigInt;
  }

  Future<BigInt> allowance({
    required String token,
    required String owner,
    required String spender,
  }) async {
    final abiList = await contracts.loadErc20Abi();
    final deployedContract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(abiList), 'ERC20'),
      EthereumAddress.fromHex(token),
    );

    final function = deployedContract.function('allowance');

    final result = await web3Client.call(
      contract: deployedContract,
      function: function,
      params: [
        EthereumAddress.fromHex(owner),
        EthereumAddress.fromHex(spender),
      ],
    );

    return result.first as BigInt;
  }

  Future<BondingCurveContract> _ensureBondingCurveContract({
    required String abi,
    required String address,
  }) async {
    if (_cachedBondingCurve != null && _cachedBondingCurve!.address == address) {
      return _cachedBondingCurve!;
    }
    _cachedBondingCurve = await contracts.loadBondingCurveContract(
      abiJson: abi,
      contractAddress: address,
    );
    return _cachedBondingCurve!;
  }

  EvmTransaction _wrapTransaction({
    required String to,
    required String data,
    required BigInt value,
  }) {
    return EvmTransaction(
      kind: 'Eip1559',
      to: to,
      data: data,
      value: value,
      maxFeePerGas: BigInt.zero,
      maxPriorityFeePerGas: BigInt.zero,
    );
  }
}

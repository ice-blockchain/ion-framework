// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
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

    final swapFunction = _findOverloadedFunction(
      deployedContract: deployedContract,
      name: 'swap',
      parameterCount: 4,
    );

    final data = swapFunction.encodeCall([
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

  Future<EvmTransaction> encodeUpdateMetadata({
    required List<int> tokenIdentifier,
    required Uint8List metadataBytes,
    required String metadataString,
    required String bondingCurveAbi,
    required String bondingCurveAddress,
    String? tokenAddress,
  }) async {
    final contract = await _ensureBondingCurveContract(
      abi: bondingCurveAbi,
      address: bondingCurveAddress,
    );

    final deployedContract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(contract.abi), 'BondingCurve'),
      EthereumAddress.fromHex(contract.address),
    );

    final updateFunction = _findUpdateMetadataFunction(deployedContract);
    final params = _buildUpdateMetadataParams(
      updateFunction.parameters,
      tokenIdentifier: tokenIdentifier,
      metadataBytes: metadataBytes,
      metadataString: metadataString,
      tokenAddress: tokenAddress,
    );
    final data = updateFunction.encodeCall(params);

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

  ContractFunction _findOverloadedFunction({
    required DeployedContract deployedContract,
    required String name,
    required int parameterCount,
  }) {
    final candidates = deployedContract.findFunctionsByName(name);
    final function = candidates.firstWhereOrNull(
      (func) => func.parameters.length == parameterCount,
    );
    if (function != null) return function;

    final signatures = candidates
        .map(
          (func) => '$name(${func.parameters.map((p) => p.type.name).join(',')})',
        )
        .join('; ');
    throw StateError(
      'Function "$name" with $parameterCount params not found. Candidates: $signatures',
    );
  }

  ContractFunction _findUpdateMetadataFunction(DeployedContract deployedContract) {
    final candidates = deployedContract.findFunctionsByName('updateMetadata');
    if (candidates.isEmpty) {
      throw StateError('Function "updateMetadata" not found in bonding curve ABI.');
    }
    return candidates.firstWhereOrNull(
          (func) => func.parameters.length <= 2,
        ) ??
        candidates.first;
  }

  List<dynamic> _buildUpdateMetadataParams(
    List<FunctionParameter<dynamic>> parameters, {
    required List<int> tokenIdentifier,
    required Uint8List metadataBytes,
    required String metadataString,
    String? tokenAddress,
  }) {
    final params = <dynamic>[];
    for (var i = 0; i < parameters.length; i++) {
      final param = parameters[i];
      final paramName = param.name.toLowerCase();
      final isMetadataParam = paramName.contains('metadata');
      final useMetadata = parameters.length == 1 || isMetadataParam || i == 1;

      params.add(
        _resolveUpdateMetadataParam(
          param: param,
          useMetadata: useMetadata,
          tokenIdentifier: tokenIdentifier,
          metadataBytes: metadataBytes,
          metadataString: metadataString,
          tokenAddress: tokenAddress,
        ),
      );
    }
    return params;
  }

  dynamic _resolveUpdateMetadataParam({
    required FunctionParameter<dynamic> param,
    required bool useMetadata,
    required List<int> tokenIdentifier,
    required Uint8List metadataBytes,
    required String metadataString,
    String? tokenAddress,
  }) {
    final typeName = param.type.name;
    if (typeName == 'address') {
      if (tokenAddress == null || tokenAddress.isEmpty) {
        throw StateError('Token address is required for updateMetadata.');
      }
      return EthereumAddress.fromHex(tokenAddress);
    }
    if (typeName == 'string') {
      return useMetadata ? metadataString : bytesToHex(tokenIdentifier);
    }
    if (typeName.startsWith('bytes')) {
      return useMetadata ? metadataBytes : Uint8List.fromList(tokenIdentifier);
    }
    throw StateError(
      'Unsupported updateMetadata param "${param.name}" of type "$typeName".',
    );
  }
}

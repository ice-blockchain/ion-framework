// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:ion_swap_client/utils/hex_helper.dart';
import 'package:ion_swap_client/utils/swap_constants.dart';
import 'package:web3dart/web3dart.dart';

// TODO(ice-erebus): move to separate package
class EvmTxBuilder {
  EvmTxBuilder({
    required this.contracts,
    required this.web3Client,
  });

  final EvmContractProviders contracts;
  final Web3Client web3Client;

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
      data: HexHelper.bytesToHex(data),
      value: BigInt.zero,
    );
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

  EvmTransaction applyDefaultFees(EvmTransaction transaction) {
    return EvmTransaction(
      kind: transaction.kind,
      to: transaction.to,
      data: transaction.data,
      value: transaction.value,
      maxFeePerGas: SwapConstants.maxFeePerGas,
      maxPriorityFeePerGas: SwapConstants.maxPriorityFeePerGas,
    );
  }

  EvmTransaction wrapTransactionBytes({
    required Uint8List bytes,
    required String to,
    required BigInt value,
  }) {
    return _wrapTransaction(
      to: to,
      data: HexHelper.bytesToHex(bytes),
      value: value,
    );
  }
}

class EvmContractProviders {
  EvmContractProviders();

  List<dynamic>? _erc20Abi;

  Future<List<dynamic>> loadErc20Abi() async {
    if (_erc20Abi != null) {
      return _erc20Abi!;
    }
    _erc20Abi = jsonDecode(_standardErc20Abi) as List<dynamic>;
    return _erc20Abi!;
  }
}

const _standardErc20Abi = '''
[
  {
    "name": "approve",
    "type": "function",
    "stateMutability": "nonpayable",
    "inputs": [
      {"name": "spender", "type": "address"},
      {"name": "amount", "type": "uint256"}
    ],
    "outputs": [{"name": "", "type": "bool"}]
  },
  {
    "name": "allowance",
    "type": "function",
    "stateMutability": "view",
    "inputs": [
      {"name": "owner", "type": "address"},
      {"name": "spender", "type": "address"}
    ],
    "outputs": [{"name": "", "type": "uint256"}]
  },
  {
    "name": "decimals",
    "type": "function",
    "stateMutability": "view",
    "inputs": [],
    "outputs": [{"name": "", "type": "uint8"}]
  }
]
''';

// TODO(ice-erebus): move to separate package
class EvmTransaction {
  EvmTransaction({
    required this.kind,
    required this.to,
    required this.data,
    required this.value,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
  });

  final String kind;
  final String to;
  final String data;
  final BigInt value;
  final BigInt maxFeePerGas;
  final BigInt maxPriorityFeePerGas;
}

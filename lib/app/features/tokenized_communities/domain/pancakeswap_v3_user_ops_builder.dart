// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/domain/pancakeswap_v3_service.dart';
import 'package:ion/app/features/tokenized_communities/models/evm_transaction.dart';
import 'package:ion/app/utils/hex_encoding.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:web3dart/web3dart.dart';

class PancakeSwapV3UserOpsBuilder {
  PancakeSwapV3UserOpsBuilder({
    required PancakeSwapV3Service pancakeSwapService,
  }) : _pancakeSwapService = pancakeSwapService;

  final PancakeSwapV3Service _pancakeSwapService;

  static const _swapRouterAbi = '''
[
  {
    "inputs": [
      {
        "components": [
          { "internalType": "address", "name": "tokenIn", "type": "address" },
          { "internalType": "address", "name": "tokenOut", "type": "address" },
          { "internalType": "uint24", "name": "fee", "type": "uint24" },
          { "internalType": "address", "name": "recipient", "type": "address" },
          { "internalType": "uint256", "name": "deadline", "type": "uint256" },
          { "internalType": "uint256", "name": "amountIn", "type": "uint256" },
          { "internalType": "uint256", "name": "amountOutMinimum", "type": "uint256" },
          { "internalType": "uint160", "name": "sqrtPriceLimitX96", "type": "uint160" }
        ],
        "internalType": "struct IV3SwapRouter.ExactInputSingleParams",
        "name": "params",
        "type": "tuple"
      }
    ],
    "name": "exactInputSingle",
    "outputs": [
      { "internalType": "uint256", "name": "amountOut", "type": "uint256" }
    ],
    "stateMutability": "payable",
    "type": "function"
  }
]
''';

  static const _erc20Abi = '''
[
  {
    "inputs": [
      { "internalType": "address", "name": "spender", "type": "address" },
      { "internalType": "uint256", "name": "amount", "type": "uint256" }
    ],
    "name": "approve",
    "outputs": [
      { "internalType": "bool", "name": "", "type": "bool" }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "deposit",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "uint256", "name": "wad", "type": "uint256" }
    ],
    "name": "withdraw",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
''';

  Future<List<EvmUserOperation>> buildSwapOperations({
    required String tokenIn,
    required String tokenOut,
    required int feeTier,
    required BigInt amountIn,
    required BigInt amountOutMinimum,
    required String recipient,
    required bool isNativeIn,
    required bool isNativeOut,
    EvmUserOperation? approvalOperation,
  }) async {
    await _pancakeSwapService.ensureRouterCompatibility();

    final effectiveTokenIn = isNativeIn ? _pancakeSwapService.wbnbTokenAddress : tokenIn;
    final effectiveTokenOut = isNativeOut ? _pancakeSwapService.wbnbTokenAddress : tokenOut;

    final ops = <EvmUserOperation>[];
    if (isNativeIn) {
      ops.add(_toUserOperation(_buildWbnbDeposit(amountIn)));
    }
    if (approvalOperation != null) {
      ops.add(approvalOperation);
    }
    ops.add(
      _toUserOperation(
        _buildSwap(
          recipient: recipient,
          tokenIn: effectiveTokenIn,
          tokenOut: effectiveTokenOut,
          feeTier: feeTier,
          amountIn: amountIn,
          amountOutMinimum: amountOutMinimum,
          isNativeIn: isNativeIn,
        ),
      ),
    );
    if (isNativeOut) {
      ops.add(_toUserOperation(_buildWbnbWithdraw(amountOutMinimum)));
    }
    return ops;
  }

  EvmTransaction _buildWbnbDeposit(BigInt amountIn) {
    final contract = DeployedContract(
      ContractAbi.fromJson(_erc20Abi, 'WBNB'),
      EthereumAddress.fromHex(_pancakeSwapService.wbnbTokenAddress),
    );
    final function = contract.function('deposit');
    final data = function.encodeCall(const []);
    return EvmTransaction(
      kind: 'Eip1559',
      to: _pancakeSwapService.wbnbTokenAddress,
      data: bytesToHex(data),
      value: amountIn,
      maxFeePerGas: BigInt.zero,
      maxPriorityFeePerGas: BigInt.zero,
    );
  }

  EvmTransaction _buildSwap({
    required String recipient,
    required String tokenIn,
    required String tokenOut,
    required int feeTier,
    required BigInt amountIn,
    required BigInt amountOutMinimum,
    required bool isNativeIn,
  }) {
    final contract = DeployedContract(
      ContractAbi.fromJson(_swapRouterAbi, 'SwapRouter'),
      EthereumAddress.fromHex(_pancakeSwapService.swapRouterAddress),
    );
    final function = contract.function('exactInputSingle');
    final deadline = BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1200);
    final data = function.encodeCall([
      [
        EthereumAddress.fromHex(tokenIn),
        EthereumAddress.fromHex(tokenOut),
        BigInt.from(feeTier),
        EthereumAddress.fromHex(recipient),
        deadline,
        amountIn,
        amountOutMinimum,
        BigInt.zero,
      ]
    ]);
    return EvmTransaction(
      kind: 'Eip1559',
      to: _pancakeSwapService.swapRouterAddress,
      data: bytesToHex(data),
      value: isNativeIn ? amountIn : BigInt.zero,
      maxFeePerGas: BigInt.zero,
      maxPriorityFeePerGas: BigInt.zero,
    );
  }

  EvmTransaction _buildWbnbWithdraw(BigInt amount) {
    final contract = DeployedContract(
      ContractAbi.fromJson(_erc20Abi, 'WBNB'),
      EthereumAddress.fromHex(_pancakeSwapService.wbnbTokenAddress),
    );
    final function = contract.function('withdraw');
    final data = function.encodeCall([amount]);
    return EvmTransaction(
      kind: 'Eip1559',
      to: _pancakeSwapService.wbnbTokenAddress,
      data: bytesToHex(data),
      value: BigInt.zero,
      maxFeePerGas: BigInt.zero,
      maxPriorityFeePerGas: BigInt.zero,
    );
  }

  EvmUserOperation _toUserOperation(EvmTransaction transaction) {
    return EvmUserOperation(
      to: transaction.to,
      data: transaction.data.isNotEmpty ? transaction.data : null,
      value: transaction.value == BigInt.zero ? null : transaction.value.toString(),
    );
  }
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/domain/tokenized_communities_trade_config.dart';
import 'package:web3dart/web3dart.dart';

class PancakeSwapV3Repository {
  PancakeSwapV3Repository({
    required this.web3Client,
    required this.tradeConfig,
  });

  final Web3Client web3Client;
  final TokenizedCommunitiesTradeConfig tradeConfig;

  String get quoterV2Address => tradeConfig.pancakeSwapQuoterV2Address;

  String get swapRouterAddress => tradeConfig.pancakeSwapSwapRouterAddress;

  // ABIs
  static const _quoterV2Abi = '''
[
  {
    "inputs": [
      {
        "components": [
          { "internalType": "address", "name": "tokenIn", "type": "address" },
          { "internalType": "address", "name": "tokenOut", "type": "address" },
          { "internalType": "uint256", "name": "amountIn", "type": "uint256" },
          { "internalType": "uint24", "name": "fee", "type": "uint24" },
          { "internalType": "uint160", "name": "sqrtPriceLimitX96", "type": "uint160" }
        ],
        "internalType": "struct IQuoterV2.QuoteExactInputSingleParams",
        "name": "params",
        "type": "tuple"
      }
    ],
    "name": "quoteExactInputSingle",
    "outputs": [
      { "internalType": "uint256", "name": "amountOut", "type": "uint256" },
      { "internalType": "uint160", "name": "sqrtPriceX96After", "type": "uint160" },
      { "internalType": "uint32", "name": "initializedTicksCrossed", "type": "uint32" },
      { "internalType": "uint256", "name": "gasEstimate", "type": "uint256" }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "components": [
          { "internalType": "address", "name": "tokenIn", "type": "address" },
          { "internalType": "address", "name": "tokenOut", "type": "address" },
          { "internalType": "uint256", "name": "amount", "type": "uint256" },
          { "internalType": "uint24", "name": "fee", "type": "uint24" },
          { "internalType": "uint160", "name": "sqrtPriceLimitX96", "type": "uint160" }
        ],
        "internalType": "struct IQuoterV2.QuoteExactOutputSingleParams",
        "name": "params",
        "type": "tuple"
      }
    ],
    "name": "quoteExactOutputSingle",
    "outputs": [
      { "internalType": "uint256", "name": "amountIn", "type": "uint256" },
      { "internalType": "uint160", "name": "sqrtPriceX96After", "type": "uint160" },
      { "internalType": "uint32", "name": "initializedTicksCrossed", "type": "uint32" },
      { "internalType": "uint256", "name": "gasEstimate", "type": "uint256" }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
''';

  Future<BigInt> quoteExactInputSingle({
    required String tokenIn,
    required String tokenOut,
    required BigInt amountIn,
    required int fee,
  }) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(_quoterV2Abi, 'QuoterV2'),
      EthereumAddress.fromHex(quoterV2Address),
    );

    final function = contract.function('quoteExactInputSingle');

    // struct QuoteExactInputSingleParams {
    //   address tokenIn;
    //   address tokenOut;
    //   uint256 amountIn;
    //   uint24 fee;
    //   uint160 sqrtPriceLimitX96;
    // }
    final params = [
      EthereumAddress.fromHex(tokenIn),
      EthereumAddress.fromHex(tokenOut),
      amountIn,
      BigInt.from(fee),
      BigInt.zero, // sqrtPriceLimitX96 = 0
    ];

    final result = await web3Client.call(
      contract: contract,
      function: function,
      params: [params],
    );

    // returns (amountOut, sqrtPriceX96After, initializedTicksCrossed, gasEstimate)
    return result[0] as BigInt;
  }

  Future<BigInt> quoteExactOutputSingle({
    required String tokenIn,
    required String tokenOut,
    required BigInt amountOut,
    required int fee,
  }) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(_quoterV2Abi, 'QuoterV2'),
      EthereumAddress.fromHex(quoterV2Address),
    );

    final function = contract.function('quoteExactOutputSingle');

    // struct QuoteExactOutputSingleParams {
    //   address tokenIn;
    //   address tokenOut;
    //   uint256 amount;
    //   uint24 fee;
    //   uint160 sqrtPriceLimitX96;
    // }
    final params = [
      EthereumAddress.fromHex(tokenIn),
      EthereumAddress.fromHex(tokenOut),
      amountOut,
      BigInt.from(fee),
      BigInt.zero, // sqrtPriceLimitX96 = 0
    ];

    final result = await web3Client.call(
      contract: contract,
      function: function,
      params: [params],
    );

    // returns (amountIn, sqrtPriceX96After, initializedTicksCrossed, gasEstimate)
    return result[0] as BigInt;
  }
}

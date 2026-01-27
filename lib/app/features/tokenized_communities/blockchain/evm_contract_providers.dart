// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

final class BondingCurveContract {
  BondingCurveContract({
    required this.address,
    required this.abi,
  });

  final String address;
  final List<dynamic> abi;
}

class EvmContractProviders {
  EvmContractProviders();

  final Map<String, BondingCurveContract> _bondingCurveCache = {};
  List<dynamic>? _erc20Abi;
  List<dynamic>? _tokenMetadataAbi;

  Future<BondingCurveContract> loadBondingCurveContract({
    required String abiJson,
    required String contractAddress,
  }) async {
    final cacheKey = '$contractAddress:${abiJson.hashCode}';
    final cached = _bondingCurveCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final parsedAbi = jsonDecode(abiJson) as List<dynamic>;
    final contract = BondingCurveContract(
      address: contractAddress,
      abi: parsedAbi,
    );
    _bondingCurveCache[cacheKey] = contract;
    return contract;
  }

  Future<List<dynamic>> loadErc20Abi() async {
    if (_erc20Abi != null) {
      return _erc20Abi!;
    }
    _erc20Abi = jsonDecode(_standardErc20Abi) as List<dynamic>;
    return _erc20Abi!;
  }

  Future<List<dynamic>> loadTokenMetadataAbi() async {
    if (_tokenMetadataAbi != null) {
      return _tokenMetadataAbi!;
    }
    _tokenMetadataAbi = jsonDecode(_tokenMetadataAbiJson) as List<dynamic>;
    return _tokenMetadataAbi!;
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

const _tokenMetadataAbiJson = '''
[
  {
    "name": "getMetadataOwner",
    "type": "function",
    "stateMutability": "view",
    "inputs": [],
    "outputs": [{"name": "", "type": "address"}]
  },
  {
    "name": "name",
    "type": "function",
    "stateMutability": "view",
    "inputs": [],
    "outputs": [{"name": "", "type": "string"}]
  },
  {
    "name": "symbol",
    "type": "function",
    "stateMutability": "view",
    "inputs": [],
    "outputs": [{"name": "", "type": "string"}]
  },
  {
    "name": "updateMetadata",
    "type": "function",
    "stateMutability": "nonpayable",
    "inputs": [
      {"name": "newName", "type": "string"},
      {"name": "newSymbol", "type": "string"}
    ],
    "outputs": []
  }
]
''';

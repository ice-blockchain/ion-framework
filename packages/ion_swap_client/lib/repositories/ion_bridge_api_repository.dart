// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:tonutils/dataformat.dart';

/// Repository for calling ION Bridge smart contract methods
/// These are TON smart contract getter methods, not HTTP endpoints
/// Reference: https://github.com/ice-adrastos/tonweb/tree/76dfd0701714c0a316aee503c2962840acaf74ef
class IonBridgeApiRepository {
  IonBridgeApiRepository({
    required Dio dio,
    required String ionRpcUrl,
    required String bridgeContractAddress,
  })  : _dio = dio,
        _ionRpcUrl = ionRpcUrl,
        _bridgeContractAddress = bridgeContractAddress;

  final Dio _dio;
  final String _ionRpcUrl;
  final String _bridgeContractAddress;

  /// Gets external voting data (oracle signatures) for a swapId
  /// This is a TON smart contract getter method: get_external_voting_data
  /// According to: https://github.com/ice-blockchain/bridge/blob/ion-mainnet/documentation/integration-vote-for-minting.md
  Future<ExternalVotingData> getExternalVotingData(String swapId) async {
    try {
      // Convert swapId hex string to bytes32 for TON contract call
      final swapIdBytes = _hexToBytes(swapId);

      // Call the TON contract getter method
      final result = await _runGetMethod(
        methodName: 'get_external_voting_data',
        params: [swapIdBytes],
      );

      // Parse the result stack from TON contract call
      final stack = result['stack'] as List<dynamic>? ?? [];
      final signatures = _parseSignaturesFromStack(stack);
      final oracleCount = await getFullOracleSet();

      return ExternalVotingData(
        signatures: signatures,
        oracleCount: oracleCount,
      );
    } catch (e) {
      throw IonSwapException('Failed to get external voting data: $e');
    }
  }

  /// Gets the full oracle set count
  /// This is a TON smart contract getter method: get_full_oracle_set
  Future<int> getFullOracleSet() async {
    try {
      final result = await _runGetMethod(
        methodName: 'get_full_oracle_set',
        params: [],
      );

      // Parse the result - should return a number (uint)
      final stack = result['stack'] as List<dynamic>? ?? [];
      if (stack.isEmpty) {
        return 0;
      }

      // TON stack format: [{"type": "int", "value": "123"}]
      final firstItem = stack.first as Map<String, dynamic>;
      final value = firstItem['value'] as String?;
      if (value == null) {
        return 0;
      }

      return int.parse(value);
    } catch (e) {
      throw IonSwapException('Failed to get oracle set: $e');
    }
  }

  /// Runs a getter method on the ION bridge contract using TON RPC
  /// This calls the contract's get method (read-only)
  Future<Map<String, dynamic>> _runGetMethod({
    required String methodName,
    required List<dynamic> params,
  }) async {
    try {
      // Build the method call
      final address = InternalAddress.parse(_bridgeContractAddress);

      // Build stack for TON RPC call
      final stack = params.map((param) {
        if (param is Uint8List) {
          // bytes32 or bytes
          return {
            'type': 'cell',
            'value': base64Encode(param),
          };
        } else if (param is BigInt) {
          return {
            'type': 'int',
            'value': param.toString(),
          };
        } else {
          return {
            'type': 'tvm.Slice',
            'value': base64Encode(utf8.encode(param.toString())),
          };
        }
      }).toList();

      // Call TON RPC runGetMethod
      // TON RPC uses JSON-RPC 2.0 format
      // Reference: https://github.com/ice-adrastos/tonweb
      // Standard TON RPC endpoint: /v2/runGetMethod
      final response = await _dio.post<dynamic>(
        '$_ionRpcUrl/v2/runGetMethod',
        data: {
          'id': DateTime.now().millisecondsSinceEpoch,
          'jsonrpc': '2.0',
          'method': 'runGetMethod',
          'params': {
            'address': address.toString(),
            'method': methodName,
            'stack': stack,
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      // Extract result from JSON-RPC response
      final jsonRpcData = response.data as Map<String, dynamic>;
      if (jsonRpcData.containsKey('error')) {
        throw IonSwapException(
          'TON RPC error: ${jsonRpcData['error']}',
        );
      }

      final result = jsonRpcData['result'] as Map<String, dynamic>? ?? jsonRpcData;
      return result;
    } on DioException catch (e) {
      throw IonSwapException('Failed to run get method $methodName: ${e.message}');
    }
  }

  Uint8List _hexToBytes(String hex) {
    if (hex.startsWith('0x')) {
      hex = hex.substring(2);
    }
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  List<OracleSignature> _parseSignaturesFromStack(List<dynamic> stack) {
    // Parse signatures from TON contract call result
    // The stack should contain a tuple or cell with signature data
    final signatures = <OracleSignature>[];

    // TON contract returns signatures in a specific format
    // This needs to be adjusted based on actual contract return format
    for (final item in stack) {
      if (item is Map<String, dynamic>) {
        // Parse signature from TON tuple/cell format
        // Format depends on contract implementation
        // Example: {"type": "tuple", "value": [signer, r, s, v]}
        final value = item['value'];
        if (value is List && value.length >= 4) {
          final signer = _parseStackValue(value[0]) as String;
          final r = _parseStackValue(value[1]) as String;
          final s = _parseStackValue(value[2]) as String;
          final v = int.parse(_parseStackValue(value[3]) as String);

          signatures.add(
            OracleSignature(
              signer: signer,
              r: r,
              s: s,
              v: v,
            ),
          );
        }
      }
    }

    return signatures;
  }

  dynamic _parseStackValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['value'] ?? value;
    }
    return value;
  }

  /// Gets transaction by hash from ION chain indexer (HTTP API)
  /// Used to extract SwapData from the transaction
  /// Endpoint: GET /indexer/v3/transactions/{txHash}
  Future<IonTransaction> getTransactionByHash(String txHash) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_ionRpcUrl/indexer/v3/transactions/$txHash',
      );

      final data = response.data as Map<String, dynamic>;
      return IonTransaction.fromJson(data);
    } on DioException catch (e) {
      throw IonSwapException('Failed to get transaction: ${e.message}');
    }
  }
}

class ExternalVotingData {
  ExternalVotingData({
    required this.signatures,
    required this.oracleCount,
  });

  final List<OracleSignature> signatures;
  final int oracleCount;
}

class OracleSignature {
  OracleSignature({
    required this.signer,
    required this.r,
    required this.s,
    required this.v,
  });

  final String signer; // Oracle public key (EVM address)
  final String r; // ECDSA signature component
  final String s; // ECDSA signature component
  final int v; // ECDSA signature component
}

class IonTransaction {
  IonTransaction({
    required this.hash,
    required this.lt,
    required this.outMessages,
  });

  factory IonTransaction.fromJson(Map<String, dynamic> json) {
    final outMessagesList = json['outMessages'] as List<dynamic>? ?? [];
    final outMessages = outMessagesList.map((e) => IonOutMessage.fromJson(e as Map<String, dynamic>)).toList();

    return IonTransaction(
      hash: json['hash'] as String? ?? '',
      lt: json['lt'] as int? ?? 0,
      outMessages: outMessages,
    );
  }

  final String hash;
  final int lt;
  final List<IonOutMessage> outMessages;
}

class IonOutMessage {
  IonOutMessage({
    required this.body,
    required this.destination,
  });

  factory IonOutMessage.fromJson(Map<String, dynamic> json) {
    return IonOutMessage(
      body: json['body'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
    );
  }

  final String body; // Base64 encoded message body
  final String destination; // Destination address
}

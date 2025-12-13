// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:ion_swap_client/repositories/ion_bridge_api_repository.dart';
import 'package:ion_swap_client/utils/evm_tx_builder.dart';
import 'package:ion_swap_client/utils/ion_identity_transaction_api.dart';
import 'package:ion_swap_client/utils/numb.dart';
import 'package:ion_swap_client/utils/swap_constants.dart';
import 'package:tonutils/dataformat.dart';
import 'package:web3dart/crypto.dart' as web3crypto;
import 'package:web3dart/web3dart.dart';

/// Bridges native ION on the ION chain to wION on BSC by sending ION to the bridge contract.
///
/// The flow follows the reference implementation documented at:
/// https://github.com/ice-blockchain/bridge/blob/ion-mainnet/documentation/integration-flow.md
/// Direction B: ION -> wION on BSC
///
/// After sending ION, the service polls for oracle signatures and calls voteForMinting
/// as documented in: https://github.com/ice-blockchain/bridge/blob/ion-mainnet/documentation/integration-vote-for-minting.md
class IonToBscBridgeService {
  IonToBscBridgeService({
    required IONSwapConfig config,
    required Web3Client web3client,
    required EvmTxBuilder evmTxBuilder,
    required IonIdentityTransactionApi ionIdentityClient,
    required IonBridgeApiRepository bridgeApiRepository,
  })  : _web3client = web3client,
        _evmTxBuilder = evmTxBuilder,
        _ionIdentityTransactionApi = ionIdentityClient,
        _bridgeApiRepository = bridgeApiRepository,
        _ionBridgeContractAddress = config.ionBridgeContractAddress,
        _ionBridgeRouterAddress = EthereumAddress.fromHex(config.ionBridgeRouterContractAddress),
        _wIonTokenAddress = config.ionBscTokenAddress.toLowerCase();

  final Web3Client _web3client;
  final EvmTxBuilder _evmTxBuilder;
  final IonIdentityTransactionApi _ionIdentityTransactionApi;
  final IonBridgeApiRepository _bridgeApiRepository;
  final String _ionBridgeContractAddress;
  final EthereumAddress _ionBridgeRouterAddress;
  final String _wIonTokenAddress;

  Future<SwapQuoteInfo> getQuote({
    required SwapCoinParameters swapCoinData,
  }) async {
    if (!isSupportedPair(swapCoinData)) {
      throw const IonSwapException('Unsupported token pair for ION → wION BSC bridge');
    }

    return SwapQuoteInfo(
      type: SwapQuoteInfoType.bridge,
      priceForSellTokenInBuyToken: 1,
      source: SwapQuoteInfoSource.ionOnchain,
    );
  }

  Future<String> bridgeToBsc({
    required SwapCoinParameters swapCoinData,
    required IonSwapRequest request,
    required OnVerifyIdentity<Map<String, dynamic>> onVerifyIdentity,
  }) async {
    if (!isSupportedPair(swapCoinData)) {
      throw const IonSwapException('Unsupported token pair for ION → wION BSC bridge');
    }

    final bscDestination = _parseBscAddress(swapCoinData.userBuyAddress);
    final amountIn = _parseAmount(swapCoinData.amount, swapCoinData.sellCoin.decimal);

    if (amountIn == BigInt.zero) {
      throw const IonSwapException('Bridge amount must be greater than zero');
    }

    // Convert amount to string in minimum denomination (nano ION)
    final amountString = amountIn.toString();

    // Step 1: Send ION to bridge contract
    // For TON-based ION, the memo field contains the message body
    // The bridge contract expects: "swapTo#<BSC_ADDRESS>" in the message body
    // Note: TON/ION uses memo field for message body content
    final transfer = NativeTokenTransfer(
      to: _ionBridgeContractAddress,
      amount: amountString,
      memo: 'swapTo#$bscDestination',
    );

    // Send the transfer using ION Identity client
    final result = await request.identityClient.wallets.makeTransfer(
      request.wallet,
      transfer,
      onVerifyIdentity,
    );

    final transferId = _extractTransferId(result);

    // Step 2: Wait for transaction confirmation on ION chain
    await _waitForTransactionConfirmation(transferId);

    // Step 3: Extract SwapData from the transaction
    final swapData = await _extractSwapData(
      transferId: transferId,
      receiver: bscDestination,
      amount: amountIn,
      userAddress: request.wallet.address ?? '',
    );

    // Step 4: Calculate swapId
    final swapId = _calculateSwapId(swapData);

    // Step 5: Poll for oracle signatures
    final signatures = await _pollForOracleSignatures(swapId);

    // Step 6: Call voteForMinting on BSC
    final mintTxHash = await _voteForMinting(
      swapData: swapData,
      signatures: signatures,
      request: request,
    );

    return mintTxHash;
  }

  bool isSupportedPair(SwapCoinParameters swapCoinData) {
    final isIonSell = swapCoinData.sellCoin.network.id.toLowerCase() == _ionNetworkId;
    final isBscTarget = swapCoinData.buyCoin.network.id.toLowerCase() == _bscNetworkId;

    if (!isIonSell || !isBscTarget) {
      return false;
    }

    // Check if selling native ION (no contract address means native token)
    final isNativeIon = swapCoinData.sellCoin.contractAddress.isEmpty ||
        swapCoinData.sellCoin.contractAddress.toLowerCase() == 'native';

    // Check if buying wION on BSC (must match the wION token address)
    final matchesWIonBscToken = swapCoinData.buyCoin.contractAddress.toLowerCase() == _wIonTokenAddress;

    return isNativeIon && matchesWIonBscToken;
  }

  String _parseBscAddress(String? address) {
    if (address == null || address.isEmpty) {
      throw const IonSwapException('BSC destination address is required for bridge');
    }

    // Validate Ethereum address format
    if (!address.startsWith('0x') || address.length != 42) {
      throw const IonSwapException('Invalid BSC destination address format');
    }

    return address;
  }

  BigInt _parseAmount(String amount, int decimals) {
    try {
      return parseAmount(amount, BigInt.from(decimals));
    } catch (e) {
      throw IonSwapException('Failed to parse amount: $e');
    }
  }

  String _extractTransferId(Map<String, dynamic> result) {
    final transferId = result['id'] as String?;
    final txHash = result['txHash'] as String?;

    return transferId ?? txHash ?? (throw const IonSwapException('Failed to extract transfer ID from bridge response'));
  }

  Future<void> _waitForTransactionConfirmation(String transferId) async {
    // Wait a bit for transaction to be processed on ION chain
    // In production, we would poll the ION chain RPC for transaction confirmation
    await Future<void>.delayed(const Duration(seconds: 5));
  }

  Future<_SwapData> _extractSwapData({
    required String transferId,
    required String receiver,
    required BigInt amount,
    required String userAddress,
  }) async {
    // Parse ION address from userAddress
    final ionAddress = InternalAddress.parse(userAddress);

    // Fetch actual transaction from ION chain indexer
    // According to documentation: https://github.com/ice-blockchain/bridge/blob/ion-mainnet/documentation/integration-vote-for-minting.md
    // The indexer API provides transaction details including tx_hash and lt
    try {
      final transaction = await _bridgeApiRepository.getTransactionByHash(transferId);

      // Find the outgoing message that matches our bridge contract and receiver
      // The message body should start with "swapTo#" and contain the BSC address
      transaction.outMessages.firstWhere(
        (msg) {
          // Check if destination is bridge contract and body contains our receiver
          final isBridgeContract = msg.destination.toLowerCase() == _ionBridgeContractAddress.toLowerCase();
          final bodyBase64 = msg.body;
          if (bodyBase64.isEmpty) return false;

          try {
            // Decode base64 body and check for "swapTo#" prefix
            final bodyBytes = base64Decode(bodyBase64);
            final bodyText = utf8.decode(bodyBytes);
            return isBridgeContract && bodyText.startsWith('swapTo#');
          } catch (e) {
            return false;
          }
        },
        orElse: () => throw const IonSwapException(
          'Bridge transaction message not found',
        ),
      );

      // Extract tx_hash and lt from the transaction
      final txHash = transaction.hash;
      final lt = transaction.lt;

      return _SwapData(
        type: 'SwapTonToEth',
        receiver: receiver,
        amount: amount.toString(),
        tx: _SwapTx(
          address: _TonAddress(
            workchain: ionAddress.workChain.toInt(),
            addressHash: ionAddress.hash,
          ),
          txHash: txHash,
          lt: lt,
        ),
      );
    } catch (e) {
      // Fallback: if indexer API fails, use transferId as txHash
      // This is a temporary workaround until indexer integration is complete
      throw IonSwapException(
        'Failed to extract swap data from transaction: $e. '
        'Please ensure the indexer API is properly configured.',
      );
    }
  }

  String _calculateSwapId(_SwapData swapData) {
    // Encode SwapData according to the contract ABI
    // The contract expects: (address receiver, uint256 amount, int8 workchain, bytes32 address_hash, bytes32 tx_hash, uint64 lt)
    // This uses manual encoding to match Solidity's abi.encode for keccak256 calculation
    try {
      final encoded = _encodeSwapDataForKeccak256(swapData);
      // Use keccak256 (same as Solidity's keccak256)
      final hash = _keccak256(encoded);
      return '0x${hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
    } catch (e) {
      throw IonSwapException('Failed to calculate swapId: $e');
    }
  }

  Uint8List _keccak256(Uint8List data) {
    // Use keccak256 (same as Solidity's keccak256)
    // web3dart provides keccak256 which matches Solidity's keccak256
    return web3crypto.keccak256(data);
  }

  Uint8List _encodeSwapDataForKeccak256(_SwapData swapData) {
    // Convert receiver address to bytes (20 bytes)
    final receiverBytes = _hexToBytes(swapData.receiver);

    // Convert amount to 32-byte big-endian
    final amountBigInt = BigInt.parse(swapData.amount);
    final amountBytes = _bigIntToBytes(amountBigInt, 32);

    // Workchain as int8 (1 byte, signed)
    final workchainBytes = Uint8List(1);
    workchainBytes[0] = swapData.tx.address.workchain & 0xFF;

    // Address hash as bytes32 (32 bytes)
    final addressHashBytes = Uint8List(32);
    addressHashBytes.setRange(
      0,
      swapData.tx.address.addressHash.length,
      swapData.tx.address.addressHash,
    );

    // Tx hash as bytes32 (32 bytes) - convert hex string to bytes
    final txHashBytes = _hexToBytes(swapData.tx.txHash);
    final txHashBytes32 = Uint8List(32);
    if (txHashBytes.length <= 32) {
      txHashBytes32.setRange(32 - txHashBytes.length, 32, txHashBytes);
    } else {
      txHashBytes32.setRange(0, 32, txHashBytes.sublist(txHashBytes.length - 32));
    }

    // LT as uint64 (8 bytes, big-endian)
    final ltBytes = _intToBytes(swapData.tx.lt, 8);

    // Concatenate all fields in order: receiver, amount, workchain, address_hash, tx_hash, lt
    return Uint8List.fromList([
      ...receiverBytes,
      ...amountBytes,
      ...workchainBytes,
      ...addressHashBytes,
      ...txHashBytes32,
      ...ltBytes,
    ]);
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

  Uint8List _bigIntToBytes(BigInt value, int length) {
    final bytes = Uint8List(length);
    var temp = value;
    for (var i = length - 1; i >= 0; i--) {
      bytes[i] = (temp & BigInt.from(0xFF)).toInt();
      temp = temp >> 8;
    }
    return bytes;
  }

  Uint8List _intToBytes(int value, int length) {
    final bytes = Uint8List(length);
    var temp = value;
    for (var i = length - 1; i >= 0; i--) {
      bytes[i] = temp & 0xFF;
      temp = temp >> 8;
    }
    return bytes;
  }

  Future<List<_OracleSignature>> _pollForOracleSignatures(String swapId) async {
    const maxAttempts = 60; // Poll for up to 5 minutes (5 second intervals)
    const pollInterval = Duration(seconds: 5);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future<void>.delayed(pollInterval);

      try {
        final votingData = await _bridgeApiRepository.getExternalVotingData(swapId);
        final oracleCount = await _bridgeApiRepository.getFullOracleSet();

        // Required threshold: signatures.length >= oraclesTotal * 2 / 3
        final requiredCount = (oracleCount * 2 / 3).ceil();

        if (votingData.signatures.length >= requiredCount) {
          return votingData.signatures
              .map(
                (sig) => _OracleSignature(
                  signer: sig.signer,
                  r: sig.r,
                  s: sig.s,
                  v: sig.v,
                ),
              )
              .toList();
        }
      } catch (e) {
        // Continue polling on error
        if (attempt == maxAttempts - 1) {
          throw IonSwapException('Failed to get oracle signatures: $e');
        }
      }
    }

    throw const IonSwapException('Timeout waiting for oracle signatures');
  }

  Future<String> _voteForMinting({
    required _SwapData swapData,
    required List<_OracleSignature> signatures,
    required IonSwapRequest request,
  }) async {
    if (request.userActionSigner == null) {
      throw const IonSwapException('User action signer is required for voteForMinting');
    }

    // Sort signatures by signer address (required by contract)
    final sortedSignatures = List<_OracleSignature>.from(signatures)..sort((a, b) => a.signer.compareTo(b.signer));

    // Prepare swapData tuple for contract call
    // Convert tx_hash hex string to bytes32
    final txHashBytes = _hexToBytes(swapData.tx.txHash);
    final txHashBytes32 = Uint8List(32);
    if (txHashBytes.length <= 32) {
      txHashBytes32.setRange(32 - txHashBytes.length, 32, txHashBytes);
    } else {
      txHashBytes32.setRange(0, 32, txHashBytes.sublist(txHashBytes.length - 32));
    }

    final swapDataTuple = [
      EthereumAddress.fromHex(swapData.receiver),
      BigInt.parse(swapData.amount),
      [
        BigInt.from(swapData.tx.address.workchain),
        swapData.tx.address.addressHash,
      ],
      txHashBytes32,
      BigInt.from(swapData.tx.lt),
    ];

    // Prepare signatures for contract call
    // Each signature is: [signer address, signature bytes (65 bytes: r + s + v)]
    final signatureData = sortedSignatures.map((sig) {
      final rBytes = _hexToBytes(sig.r);
      final sBytes = _hexToBytes(sig.s);
      final vByte = Uint8List.fromList([sig.v]);
      final signatureBytes = Uint8List.fromList([...rBytes, ...sBytes, ...vByte]);

      return [
        EthereumAddress.fromHex(sig.signer),
        signatureBytes,
      ];
    }).toList();

    // Encode voteForMinting function call
    final contract = _ionBridgeRouterContract;
    final function = contract.function('voteForMinting');
    final data = function.encodeCall([
      swapDataTuple,
      signatureData,
    ]);

    final tx = _evmTxBuilder.wrapTransactionBytes(
      bytes: data,
      value: BigInt.zero,
      to: _ionBridgeRouterAddress.hex,
    );

    final txWithFees = _applyFees(
      tx,
      maxFeePerGas: SwapConstants.maxFeePerGas,
      maxPriorityFeePerGas: SwapConstants.maxPriorityFeePerGas,
    );

    final txHash = await _signAndBroadcast(
      request: request,
      transaction: txWithFees,
    );

    if (!_isBscTxHash(txHash)) {
      throw const IonSwapException('voteForMinting failed on-chain');
    }

    await _waitForBscConfirmation(txHash);

    return txHash;
  }

  DeployedContract get _ionBridgeRouterContract => DeployedContract(
        _ionBridgeRouterAbiParsed,
        _ionBridgeRouterAddress,
      );

  static final ContractAbi _ionBridgeRouterAbiParsed = ContractAbi.fromJson(_ionBridgeRouterAbi, 'IONBridgeRouter');

  static const _ionBridgeRouterAbi = '''
[
  {
    "inputs": [
      {
        "components": [
          {"internalType": "address", "name": "receiver", "type": "address"},
          {"internalType": "uint256", "name": "amount", "type": "uint256"},
          {
            "components": [
              {"internalType": "int8", "name": "workchain", "type": "int8"},
              {"internalType": "bytes32", "name": "address_hash", "type": "bytes32"}
            ],
            "internalType": "struct TonAddress",
            "name": "addr",
            "type": "tuple"
          },
          {"internalType": "bytes32", "name": "tx_hash", "type": "bytes32"},
          {"internalType": "uint64", "name": "lt", "type": "uint64"}
        ],
        "internalType": "struct SwapData",
        "name": "swapData",
        "type": "tuple"
      },
      {
        "components": [
          {"internalType": "address", "name": "signer", "type": "address"},
          {"internalType": "bytes", "name": "signature", "type": "bytes"}
        ],
        "internalType": "struct Signature[]",
        "name": "signatures",
        "type": "tuple[]"
      }
    ],
    "name": "voteForMinting",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
''';

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
      throw const IonSwapException('User action signer is required for voteForMinting');
    }

    return _ionIdentityTransactionApi.signAndBroadcast(
      walletId: request.wallet.id,
      transaction: transaction,
      userActionSigner: userActionSigner,
    );
  }

  bool _isBscTxHash(String txHash) {
    return txHash.startsWith('0x') && txHash.length == 66;
  }

  Future<TransactionReceipt> _waitForBscConfirmation(
    String txHash, {
    int maxTries = 20,
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    for (var i = 0; i < maxTries; i++) {
      final receipt = await _web3client.getTransactionReceipt(txHash);
      if (receipt != null) {
        if (receipt.status ?? false) return receipt;
        throw const IonSwapException('voteForMinting failed on-chain');
      }
      await Future<void>.delayed(pollInterval);
    }
    throw const IonSwapException('Timed out waiting for voteForMinting confirmation');
  }

  static const _ionNetworkId = 'ion';
  static const _bscNetworkId = 'bsc';
}

class _SwapData {
  _SwapData({
    required this.type,
    required this.receiver,
    required this.amount,
    required this.tx,
  });

  final String type;
  final String receiver;
  final String amount;
  final _SwapTx tx;
}

class _SwapTx {
  _SwapTx({
    required this.address,
    required this.txHash,
    required this.lt,
  });

  final _TonAddress address;
  final String txHash;
  final int lt;
}

class _TonAddress {
  _TonAddress({
    required this.workchain,
    required this.addressHash,
  });

  final int workchain;
  final Uint8List addressHash;
}

class _OracleSignature {
  _OracleSignature({
    required this.signer,
    required this.r,
    required this.s,
    required this.v,
  });

  final String signer;
  final String r;
  final String s;
  final int v;
}

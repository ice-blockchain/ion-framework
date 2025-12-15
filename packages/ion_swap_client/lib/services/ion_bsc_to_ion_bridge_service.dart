// SPDX-License-Identifier: ice License 1.0

import 'dart:typed_data';

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/services/ion_service.dart';
import 'package:ion_swap_client/utils/numb.dart';
import 'package:tonutils/dataformat.dart';
import 'package:web3dart/web3dart.dart';

/// Bridges wION on BSC to native ION on the ION chain by burning wION.
///
/// The flow follows the reference implementation documented at:
/// https://github.com/ice-blockchain/bridge/blob/ion-mainnet/documentation/integration-flow.md
class IonBscToIonBridgeService extends IonService {
  IonBscToIonBridgeService({
    required super.evmTxBuilder,
    required super.ionIdentityClient,
    required super.web3client,
    required IONSwapConfig config,
  })  : _wIonTokenAddress = EthereumAddress.fromHex(config.ionBscTokenAddress),
        _ionBridgeRouterAddress = EthereumAddress.fromHex(config.ionBridgeRouterContractAddress);

  final EthereumAddress _wIonTokenAddress;
  final EthereumAddress _ionBridgeRouterAddress;

  Future<String> bridgeToIon({
    required SwapCoinParameters swapCoinData,
    required IonSwapRequest request,
  }) async {
    if (!isSupportedPair(swapCoinData)) {
      throw const IonSwapException('Unsupported token pair for ION BSC → ION bridge');
    }

    final ionDestination = _parseIonAddress(swapCoinData.userBuyAddress);
    final tokenDecimals = await fetchDecimals(_wIonTokenAddress);

    final amountIn = parseAmount(
      swapCoinData.amount,
      tokenDecimals,
    );

    if (amountIn == BigInt.zero) {
      throw const IonSwapException('Bridge amount must be greater than zero');
    }

    final owner = toEthereumAddress(request.wallet.address);

    await ensureAllowance(
      owner: owner,
      token: _wIonTokenAddress,
      amount: amountIn,
      request: request,
      tokenDecimals: swapCoinData.sellCoin.decimal,
      spender: _ionBridgeRouterAddress,
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

    final burnTx = evmTxBuilder.wrapTransactionBytes(
      bytes: data,
      value: BigInt.zero,
      to: _ionBridgeRouterAddress.hex,
    );

    final txWithFees = evmTxBuilder.applyDefaultFees(
      burnTx,
    );

    final txHash = await signAndBroadcast(
      request: request,
      transaction: txWithFees,
    );

    if (!isBscTxHash(txHash)) {
      throw const IonSwapException('Bridge burn failed on-chain');
    }

    await waitForConfirmation(txHash);

    return txHash;
  }

  bool isSupportedPair(SwapCoinParameters swapCoinData) {
    final isBscSell = swapCoinData.sellCoin.network.id.toLowerCase() == IonService.bscNetworkId;
    final isIonTarget = swapCoinData.buyCoin.network.id.toLowerCase() == IonService.ionNetworkId;

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
}

class _IonTonAddress {
  _IonTonAddress({
    required this.workchain,
    required this.addressHash,
  });

  final int workchain;
  final Uint8List addressHash;
}

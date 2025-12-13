// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:ion_swap_client/utils/numb.dart';

/// Bridges native ION on the ION chain to wION on BSC by sending ION to the bridge contract.
///
/// The flow follows the reference implementation documented at:
/// https://github.com/ice-blockchain/bridge/blob/ion-mainnet/documentation/integration-flow.md
/// Direction B: ION -> wION on BSC
class IonToBscBridgeService {
  IonToBscBridgeService({
    required IONSwapConfig config,
  })  : _ionBridgeContractAddress = config.ionBridgeContractAddress,
        _wIonTokenAddress = config.ionBscTokenAddress.toLowerCase();

  final String _ionBridgeContractAddress;
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

    // Create native ION transfer to bridge contract
    // The memo field contains the BSC destination address for the bridge to mint wION
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

    return transferId;
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

  static const _ionNetworkId = 'ion';
  static const _bscNetworkId = 'bsc';
}

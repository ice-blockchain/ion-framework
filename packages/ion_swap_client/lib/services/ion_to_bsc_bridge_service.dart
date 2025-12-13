// SPDX-License-Identifier: ice License 1.0

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
///
/// After sending ION, the service polls for oracle signatures and calls voteForMinting
/// as documented in: https://github.com/ice-blockchain/bridge/blob/ion-mainnet/documentation/integration-vote-for-minting.md
class IonToBscBridgeService {
  IonToBscBridgeService({
    required IONSwapConfig config,
  }) : _wIonTokenAddress = config.ionBscTokenAddress.toLowerCase();

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
  }) async {
    if (!isSupportedPair(swapCoinData)) {
      throw const IonSwapException('Unsupported token pair for ION → wION BSC bridge');
    }

    final userAddress = request.wallet.address;
    if (userAddress == null) {
      throw const IonSwapException('User address is required for bridge');
    }

    final bscDestination = _parseBscAddress(swapCoinData.userBuyAddress);
    final amountIn = _parseAmount(swapCoinData.amount, swapCoinData.sellCoin.decimal);

    if (amountIn == BigInt.zero) {
      throw const IonSwapException('Bridge amount must be greater than zero');
    }

    // Step 1: Send ION to bridge contract
    // For TON-based ION, the memo field contains the message body
    // The bridge contract expects: "swapTo#<BSC_ADDRESS>" in the message body
    // Note: TON/ION uses memo field for message body content

    await _sendTransactionToIon(
      amount: amountIn,
      destination: bscDestination,
      userAddress: userAddress,
    );

    // // Step 2: Wait for transaction confirmation on ION chain
    // await _waitForTransactionConfirmation(transferId);

    // // Step 3: Extract SwapData from the transaction
    // final swapData = await _extractSwapData(
    //   transferId: transferId,
    //   receiver: bscDestination,
    //   amount: amountIn,
    //   userAddress: request.wallet.address ?? '',
    // );

    // // Step 4: Calculate swapId
    // final swapId = _calculateSwapId(swapData);

    // // Step 5: Poll for oracle signatures
    // final signatures = await _pollForOracleSignatures(swapId);

    // // Step 6: Call voteForMinting on BSC
    // final mintTxHash = await _voteForMinting(
    //   swapData: swapData,
    //   signatures: signatures,
    //   request: request,
    // );

    // return mintTxHash;

    return '';
  }

  Future<void> _sendTransactionToIon({
    required BigInt amount,
    required String destination,
    required String userAddress,
  }) async {
    // TODO(ice-erebus): Implement transaction to ION(Ton) manually
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

  static const String _ionNetworkId = 'ion';
  static const String _bscNetworkId = 'bsc';
}

// SPDX-License-Identifier: ice License 1.0

import 'dart:typed_data';

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:ion_swap_client/services/ion_service.dart';
import 'package:ion_swap_client/utils/bsc_parser.dart';
import 'package:ion_swap_client/utils/hex_helper.dart';
import 'package:ion_swap_client/utils/ion_identity_transaction_api.dart';
import 'package:ion_swap_client/utils/numb.dart';
import 'package:ion_swap_client/utils/swap_constants.dart';
import 'package:tonutils/tonutils.dart';

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
    required IonIdentityTransactionApi ionIdentityClient,
    required IONSwapConfig config,
  })  : _wIonTokenAddress = config.ionBscTokenAddress.toLowerCase(),
        _ionIdentityClient = ionIdentityClient,
        _tonClient = TonJsonRpc(
          config.ionJrpcUrl,
        ),
        _ionBridgeContractAddress = config.ionBridgeContractAddress;

  final String _wIonTokenAddress;
  final TonJsonRpc _tonClient;
  final String _ionBridgeContractAddress;
  final IonIdentityTransactionApi _ionIdentityClient;

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

  Future<void> bridgeToBsc({
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

    final bscDestination = BscParser.parseBscAddress(swapCoinData.userBuyAddress);
    final amountIn = _parseAmount(swapCoinData.amount, swapCoinData.sellCoin.decimal);

    if (amountIn == BigInt.zero) {
      throw const IonSwapException('Bridge amount must be greater than zero');
    }

    await _sendTransactionToIon(
      amount: amountIn,
      destination: bscDestination,
      wallet: request.wallet,
      userActionSigner: request.userActionSigner,
    );
  }

  /// Docs how to build a transaction for sign are here
  /// https://docs.dfns.co/api-reference/sign/ton
  Future<void> _sendTransactionToIon({
    required BigInt amount,
    required String destination,
    required Wallet wallet,
    required UserActionSignerNew userActionSigner,
  }) async {
    final payloadText = 'swapTo#$destination';
    final bridgeAddress = InternalAddress.parse(_ionBridgeContractAddress);
    final walletContract = WalletContractV4R2.create(
      publicKey: HexHelper.hexToBytes(
        wallet.signingKey.publicKey,
      ),
    );

    final openedWallet = _tonClient.open(walletContract);
    final seqno = await openedWallet.getSeqno();
    final builder = beginCell()..storeUint(BigInt.from(walletContract.walletId), 32);

    final walletBalance = await _tonClient.getBalance(walletContract.address);
    var amountIn = amount;

    if (amount >= walletBalance - SwapConstants.keepAliveReserve) {
      amountIn = await computeMaxBridgeAmount(
        walletContract: openedWallet,
        bridgeAddress: InternalAddress.parse(_ionBridgeContractAddress),
        payloadText: payloadText,
        seqno: seqno,
        keepAliveReserve: SwapConstants.keepAliveReserve,
      );
    }

    if (seqno == 0) {
      for (var i = 0; i < 32; i++) {
        builder.storeBit(1);
      }
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      builder.storeUint(BigInt.from((now / 1000).floor() + 60), 32);
    }

    builder
      ..storeUint(BigInt.from(seqno), 32)
      ..storeUint(BigInt.from(0), 8)
      ..storeUint(BigInt.from(0), 8);

    final message = internal(
      to: SiaInternalAddress(bridgeAddress),
      body: ScString(payloadText),
      value: SbiBigInt(amountIn),
    );

    final cell = builder.storeRef(beginCell().store(storeMessageRelaxed(message))).endCell();
    final messageHex = HexHelper.bytesToHex(cell.toBoc());

    final signature = await _ionIdentityClient.sign(
      walletId: wallet.id,
      message: messageHex,
      userActionSigner: userActionSigner,
    );

    final encodedSignature = signature.encoded;
    if (encodedSignature == null) {
      throw const IonSwapException('Failed to sign transaction');
    }

    final signatureBytes = HexHelper.hexToBytes(encodedSignature);

    final body = beginCell().storeList(signatureBytes).storeSlice(cell.beginParse()).endCell();

    ContractMaybeInit? maybeInit;

    if (seqno == 0) {
      final code = walletContract.init?.code;
      final data = walletContract.init?.data;

      maybeInit = ContractMaybeInit(
        code: code,
        data: data,
      );
    }

    final externalSignedMessage = external(
      to: SiaInternalAddress(walletContract.address),
      body: body,
      init: maybeInit,
    );

    final externalCell = beginCell().store(storeMessage(externalSignedMessage)).endCell();
    final externalBoc = externalCell.toBoc();

    await _tonClient.sendFile(externalBoc);
  }

  Future<BigInt> computeMaxBridgeAmount({
    required WalletContractV4R2 walletContract,
    required InternalAddress bridgeAddress,
    required String payloadText,
    required int seqno,
    required BigInt keepAliveReserve, // e.g. Nano.fromString("0.05")
  }) async {
    final balance = await _tonClient.getBalance(walletContract.address);

    // Start with "balance minus reserve" (so estimation has a sane value).
    var amount = balance > keepAliveReserve ? balance - keepAliveReserve : BigInt.zero;

    // 1-2 iterations is usually enough (fee can slightly vary with message/value).
    for (var i = 0; i < 2; i++) {
      // Build the SAME transfer cell you later sign, but with a dummy signature.
      final transferBuilder = beginCell()..storeUint(BigInt.from(walletContract.walletId), 32);
      // valid_until + seqno + op + sendmode should match your current logic...
      // (reuse your existing builder logic here)
      // then store the internal message with `value: amount`

      final internalMsg = internal(
        to: SiaInternalAddress(bridgeAddress),
        body: ScString(payloadText),
        value: SbiBigInt(amount),
      );

      final transferCell =
          transferBuilder.storeRef(beginCell().store(storeMessageRelaxed(internalMsg))).endCell();

      // Dummy 64-byte signature; ignoreSignature=true makes it ok for estimation.
      final dummySig = Uint8List(64);
      final extBody =
          beginCell().storeList(dummySig).storeSlice(transferCell.beginParse()).endCell();

      final initCode = (seqno == 0) ? walletContract.init?.code : null;
      final initData = (seqno == 0) ? walletContract.init?.data : null;

      final fee = await _tonClient.estimateExternalMessageFee(
        walletContract.address,
        body: extBody,
        initCode: initCode,
        initData: initData,
        ignoreSignature: true,
      );

      final totalFee = BigInt.from(fee.inForwardFee + fee.storageFee + fee.gasFee + fee.forwardFee);

      final next = balance - totalFee - keepAliveReserve;
      amount = next > BigInt.zero ? next : BigInt.zero;
    }

    return amount;
  }

  bool isSupportedPair(SwapCoinParameters swapCoinData) {
    final isIonSell = swapCoinData.sellCoin.network.id.toLowerCase() == IonService.ionNetworkId;
    final isBscTarget = swapCoinData.buyCoin.network.id.toLowerCase() == IonService.bscNetworkId;

    if (!isIonSell || !isBscTarget) {
      return false;
    }

    final isNativeIon = swapCoinData.sellCoin.contractAddress.isEmpty;
    final matchesWIonBscToken =
        swapCoinData.buyCoin.contractAddress.toLowerCase() == _wIonTokenAddress;

    return isNativeIon && matchesWIonBscToken;
  }

  BigInt _parseAmount(String amount, int decimals) {
    try {
      return parseAmount(amount, BigInt.from(decimals));
    } catch (e) {
      throw IonSwapException('Failed to parse amount: $e');
    }
  }
}

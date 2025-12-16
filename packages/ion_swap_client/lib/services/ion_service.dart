// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/utils/erc20_contract.dart';
import 'package:ion_swap_client/utils/evm_tx_builder.dart';
import 'package:ion_swap_client/utils/ion_identity_transaction_api.dart';
import 'package:ion_swap_client/utils/swap_constants.dart';
import 'package:web3dart/web3dart.dart';

class IonService {
  IonService({
    required EvmTxBuilder evmTxBuilder,
    required IonIdentityTransactionApi ionIdentityClient,
    required Web3Client web3client,
  })  : _evmTxBuilder = evmTxBuilder,
        _ionIdentityClient = ionIdentityClient,
        _web3client = web3client;

  final EvmTxBuilder _evmTxBuilder;
  final IonIdentityTransactionApi _ionIdentityClient;
  final Web3Client _web3client;

  EvmTxBuilder get evmTxBuilder => _evmTxBuilder;
  IonIdentityTransactionApi get ionIdentityClient => _ionIdentityClient;
  Web3Client get web3client => _web3client;

  Future<SwapQuoteInfo> getQuote({
    required SwapCoinParameters swapCoinData,
    required BigInt bscBalance,
  }) async {
    await ensureEnoughGasOnBsc(bscBalance);

    return SwapQuoteInfo(
      type: SwapQuoteInfoType.bridge,
      priceForSellTokenInBuyToken: 1,
      source: SwapQuoteInfoSource.ionOnchain,
    );
  }

  Future<void> ensureEnoughGasOnBsc(BigInt bscBalance) async {
    final fees = await _getFeesOnBsc();
    const gasLimit = 200000;

    // Convert maxFeePerGas from gwei to wei (1 gwei = 10^9 wei)
    final gweiToWei = BigInt.from(10).pow(9);
    final maxFeePerGasInWei = fees.maxFeePerGas * gweiToWei;

    final totalFeeInWei = BigInt.from(gasLimit) * maxFeePerGasInWei;

    // Convert bscBalance from BNB to wei (1 BNB = 10^18 wei)
    final bnbToWei = BigInt.from(10).pow(18);
    final bscBalanceInWei = bscBalance * bnbToWei;

    if (bscBalanceInWei < totalFeeInWei) {
      throw const NotEnoughGasOnBscException(
        'Insufficient BNB balance to cover gas fees',
      );
    }
  }

  Future<void> ensureAllowance({
    required EthereumAddress owner,
    required EthereumAddress token,
    required BigInt amount,
    required IonSwapRequest request,
    required int tokenDecimals,
    required EthereumAddress spender,
  }) async {
    final allowance = await _evmTxBuilder.allowance(
      token: token.hex,
      owner: owner.hex,
      spender: spender.hex,
    );

    if (allowance < amount) {
      // Approve 1 Trillion tokens (10^12) with token decimals
      final trillionAmount = BigInt.from(10).pow(12 + tokenDecimals);

      final approvalTx = await _evmTxBuilder.encodeApprove(
        token: token.hex,
        spender: spender.hex,
        amount: trillionAmount,
      );

      final tx = _evmTxBuilder.applyDefaultFees(
        approvalTx,
      );

      await signAndBroadcast(
        request: request,
        transaction: tx,
      );

      await Future<void>.delayed(SwapConstants.delayAfterApproveDuration);

      final allowance2 = await _evmTxBuilder.allowance(
        token: token.hex,
        owner: owner.hex,
        spender: spender.hex,
      );

      if (allowance2 < amount) {
        throw const IonSwapException('Failed to approve token allowance');
      }
    }
  }

  Future<String> signAndBroadcast({
    required IonSwapRequest request,
    required EvmTransaction transaction,
  }) async {
    final userActionSigner = request.userActionSigner;

    return _ionIdentityClient.signAndBroadcast(
      walletId: request.wallet.id,
      transaction: transaction,
      userActionSigner: userActionSigner,
    );
  }

  EthereumAddress toEthereumAddress(String? address) {
    if (address == null || address.isEmpty) {
      throw const IonSwapException('Wallet address is required for ion swap');
    }

    return EthereumAddress.fromHex(address);
  }

  Future<BigInt> fetchDecimals(EthereumAddress token) async {
    final decimalsFunction = Erc20Contract.contractFor(token).function('decimals');

    final result = await _web3client.call(
      contract: Erc20Contract.contractFor(token),
      function: decimalsFunction,
      params: const [],
    );

    if (result.isEmpty || result.first is! BigInt) {
      throw const IonSwapException('Failed to fetch token decimals');
    }

    return result.first as BigInt;
  }

  Future<TransactionReceipt> waitForConfirmation(
    String txHash, {
    int maxTries = 20,
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    for (var i = 0; i < maxTries; i++) {
      final receipt = await web3client.getTransactionReceipt(txHash);
      if (receipt != null) {
        if (receipt.status ?? false) return receipt;
        throw const IonSwapException('Swap failed on-chain');
      }
      await Future<void>.delayed(pollInterval);
    }
    throw const IonSwapException('Timed out waiting for confirmation');
  }

  bool isBscTxHash(String txHash) {
    return txHash.startsWith('0x') && txHash.length == 66;
  }

  static const bscNetworkId = 'bsc';
  static const ionNetworkId = 'ion';
}

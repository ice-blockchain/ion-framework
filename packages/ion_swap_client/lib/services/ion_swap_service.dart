// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:ion_swap_client/services/ion_service.dart';
import 'package:ion_swap_client/utils/evm_tx_builder.dart';
import 'package:ion_swap_client/utils/ion_identity_transaction_api.dart';
import 'package:ion_swap_client/utils/numb.dart';
import 'package:web3dart/web3dart.dart';

/// Service for swapping ICE BSC to ION BSC and vice versa.
///
/// The flow follows the reference implementation documented at:
/// https://github.com/ice-blockchain/bridge/blob/ion-mainnet/documentation/ice-wrapped-ice-swap-flow.md
class IonSwapService extends IonService {
  factory IonSwapService({
    required IONSwapConfig config,
    required Web3Client web3client,
    required EvmTxBuilder evmTxBuilder,
    required IonIdentityTransactionApi ionIdentityClient,
  }) {
    return IonSwapService._(
      config: config,
      web3client: web3client,
      evmTxBuilder: evmTxBuilder,
      ionIdentityClient: ionIdentityClient,
    );
  }

  IonSwapService._({
    required super.evmTxBuilder,
    required super.ionIdentityClient,
    required super.web3client,
    required IONSwapConfig config,
  })  : _ionSwapAddress = EthereumAddress.fromHex(config.ionSwapContractAddress),
        _iceTokenAddress = EthereumAddress.fromHex(config.iceBscTokenAddress),
        _ionTokenAddress = EthereumAddress.fromHex(config.ionBscTokenAddress);

  final EthereumAddress _ionSwapAddress;
  final EthereumAddress _iceTokenAddress;
  final EthereumAddress _ionTokenAddress;

  @override
  Future<SwapQuoteInfo> getQuote({
    required SwapCoinParameters swapCoinData,
    required BigInt bscBalance,
  }) async {
    final direction = _getDirection(swapCoinData);
    if (!direction.isIceToIon) {
      throw const IonSwapCoinPairNotFoundException();
    }

    await ensureEnoughGasOnBsc(bscBalance);

    return SwapQuoteInfo(
      type: SwapQuoteInfoType.bridge,
      priceForSellTokenInBuyToken: 1,
      source: SwapQuoteInfoSource.ionOnchain,
    );
  }

  Future<String> swapCoins({
    required SwapCoinParameters swapCoinData,
    required IonSwapRequest request,
  }) async {
    final direction = _getDirection(swapCoinData);
    final sellDecimals = await fetchDecimals(direction.sellToken);

    final amountIn = parseAmount(
      swapCoinData.amount,
      sellDecimals,
    );

    if (amountIn == BigInt.zero) {
      throw const IonSwapException('Swap amount must be greater than zero');
    }

    final owner = toEthereumAddress(request.wallet.address);

    await ensureAllowance(
      owner: owner,
      token: direction.sellToken,
      amount: amountIn,
      request: request,
      tokenDecimals: swapCoinData.sellCoin.decimal,
      spender: _ionSwapAddress,
    );

    final txHash = await _swap(
      direction: direction,
      amountIn: amountIn,
      request: request,
    );

    if (!isBscTxHash(txHash)) {
      throw IonSwapException('Swap failed on-chain, wrong tx hash: $txHash');
    }

    await waitForConfirmation(txHash);

    return txHash;
  }

  Future<String> _swap({
    required _SwapDirection direction,
    required BigInt amountIn,
    required IonSwapRequest request,
  }) async {
    final swapFunction = direction.isIceToIon ? 'swapTokens' : 'swapTokensBack';
    final function = _ionSwapContract.function(swapFunction);

    final data = function.encodeCall(
      [
        amountIn,
      ],
    );

    final tx = evmTxBuilder.wrapTransactionBytes(
      bytes: data,
      value: BigInt.zero,
      to: _ionSwapAddress.hex,
    );

    return signAndBroadcast(
      request: request,
      transaction: tx,
    );
  }

  bool isSupportedPair(SwapCoinParameters swapCoinData) {
    final isBsc = swapCoinData.sellCoin.network.id.toLowerCase() == IonService.bscNetworkId &&
        swapCoinData.buyCoin.network.id.toLowerCase() == IonService.bscNetworkId;

    if (!isBsc) {
      return false;
    }

    return _matchesAddress(swapCoinData.sellCoin.contractAddress, _iceTokenAddress) &&
            _matchesAddress(swapCoinData.buyCoin.contractAddress, _ionTokenAddress) ||
        _matchesAddress(swapCoinData.sellCoin.contractAddress, _ionTokenAddress) &&
            _matchesAddress(swapCoinData.buyCoin.contractAddress, _iceTokenAddress);
  }

  _SwapDirection _getDirection(SwapCoinParameters swapCoinData) {
    final isIceToIon = _matchesAddress(swapCoinData.sellCoin.contractAddress, _iceTokenAddress) &&
        _matchesAddress(swapCoinData.buyCoin.contractAddress, _ionTokenAddress);

    final isIonToIce = _matchesAddress(swapCoinData.sellCoin.contractAddress, _ionTokenAddress) &&
        _matchesAddress(swapCoinData.buyCoin.contractAddress, _iceTokenAddress);

    if (!isIceToIon && !isIonToIce) {
      throw const IonSwapException('Unsupported token pair for on-chain ION swap');
    }

    return _SwapDirection(
      isIceToIon: isIceToIon,
      sellToken: isIceToIon ? _iceTokenAddress : _ionTokenAddress,
      buyToken: isIceToIon ? _ionTokenAddress : _iceTokenAddress,
    );
  }

  bool _matchesAddress(String candidate, EthereumAddress expected) {
    return candidate.toLowerCase() == expected.hex.toLowerCase();
  }

  DeployedContract get _ionSwapContract => DeployedContract(
        _ionSwapAbiParsed,
        _ionSwapAddress,
      );

  static final ContractAbi _ionSwapAbiParsed = ContractAbi.fromJson(_ionSwapAbi, 'IONSwap');

  static const _ionSwapAbi = '''
[
  {"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"swapTokens","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"swapTokensBack","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"getPooledAmountOut","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"getOtherAmountOut","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}
]
''';
}

class _SwapDirection {
  _SwapDirection({
    required this.isIceToIon,
    required this.sellToken,
    required this.buyToken,
  });

  final bool isIceToIon;
  final EthereumAddress sellToken;
  final EthereumAddress buyToken;
}

// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/network_fee_information.f.dart';
import 'package:ion/app/features/wallets/model/network_fee_option.f.dart';
import 'package:ion/app/features/wallets/model/network_fee_type.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart' as ion;
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_fee_provider.r.g.dart';

@riverpod
Future<NetworkFeeInformation?> networkFee(
  Ref ref, {
  required NetworkData network,
  required String? walletId,
  CoinData? transferredCoin,
}) async {
  if (walletId == null) {
    Logger.error('Cannot load fees info without walletId');
    return null;
  }

  final client = await ref.read(ionIdentityClientProvider.future);

  final estimateFees =
      await client.networks.getEstimateFees(network: network.id).onError((error, stack) {
    Logger.error('Cannot load fees info. $error', stackTrace: stack);
    return ion.EstimateFee(network: network.id);
  });

  final walletAssets =
      await client.wallets.getWalletAssets(walletId).then((result) => result.assets);

  final networkNativeToken = walletAssets.firstWhereOrNull((asset) => asset.isNative);
  final sendableAsset = _getSendableAsset(walletAssets, transferredCoin);

  if (sendableAsset == null || networkNativeToken == null) {
    Logger.error(
      'Cannot load fees info. '
      '${sendableAsset == null ? 'sendableAsset' : 'networkNativeToken'} is null.',
    );
    return null;
  }

  final nativeCoin =
      await ref.read(coinsServiceProvider.future).then((service) => service.getNativeCoin(network));

  if (nativeCoin == null) {
    Logger.error('Cannot load fees info. nativeCoin is null.');
    return NetworkFeeInformation(
      networkNativeToken: networkNativeToken,
      sendableAsset: sendableAsset,
      networkFeeOptions: [],
    );
  }

  final networkFeeOptions = buildNetworkFeeOptions(
    estimateFees: estimateFees,
    nativeCoin: nativeCoin,
    networkNativeToken: networkNativeToken,
  );

  return NetworkFeeInformation(
    networkNativeToken: networkNativeToken,
    sendableAsset: sendableAsset,
    networkFeeOptions: networkFeeOptions,
  );
}

ion.WalletAsset? _getSendableAsset(List<ion.WalletAsset> assets, CoinData? transferredCoin) {
  ion.WalletAsset? nativeAsset() => assets.firstWhereOrNull((asset) => asset.isNative);

  if (transferredCoin == null || transferredCoin.native) {
    return nativeAsset();
  }

  final result = assets.firstWhereOrNull(
    (asset) => asset.symbol.toLowerCase() == transferredCoin.abbreviation.toLowerCase(),
  );
  // Can be native token of the testnet, if result is null
  return result ?? nativeAsset();
}

@visibleForTesting
List<NetworkFeeOption> buildNetworkFeeOptions({
  required ion.EstimateFee estimateFees,
  required CoinData nativeCoin,
  required ion.WalletAsset networkNativeToken,
}) {
  return [
    if (estimateFees.slow != null)
      _buildNetworkFeeOption(
        estimateFees.slow!,
        NetworkFeeType.slow,
        nativeCoin,
        networkNativeToken,
      ),
    if (estimateFees.standard != null)
      _buildNetworkFeeOption(
        estimateFees.standard!,
        NetworkFeeType.standard,
        nativeCoin,
        networkNativeToken,
      ),
    if (estimateFees.fast != null)
      _buildNetworkFeeOption(
        estimateFees.fast!,
        NetworkFeeType.fast,
        nativeCoin,
        networkNativeToken,
      ),
  ];
}

NetworkFeeOption _buildNetworkFeeOption(
  ion.NetworkFee fee,
  NetworkFeeType type,
  CoinData nativeCoin,
  ion.WalletAsset networkNativeToken,
) {
  final amount = _calculateFeeAmount(fee, nativeCoin.network.isBitcoin, networkNativeToken);

  return NetworkFeeOption(
    amount: amount,
    priceUSD: amount * nativeCoin.priceUSD,
    symbol: nativeCoin.abbreviation,
    arrivalTime: fee.waitTime,
    type: type,
  );
}

double _calculateFeeAmount(
  ion.NetworkFee fee,
  bool isBitcoinNetwork,
  ion.WalletAsset networkNativeToken,
) {
  if (isBitcoinNetwork && fee.feeRate != null) {
    // Bitcoin: feeRate is satoshis/vByte, multiply by estimated tx size and convert to BTC
    // Using typical Bitcoin transaction size of ~250 vBytes for simple transfer
    const estimatedTxSizeVBytes = 250.0;
    const satoshisPerBTC = 100000000;
    final feeRateSatsPerVByte = double.parse(fee.feeRate!);
    final totalSatoshis = feeRateSatsPerVByte * estimatedTxSizeVBytes;
    // Convert satoshis to BTC
    return totalSatoshis / satoshisPerBTC;
  }

  if (fee.maxFeePerGas != null) {
    // EVM and other networks: use maxFeePerGas divided by decimals
    return double.parse(fee.maxFeePerGas!) / pow(10, networkNativeToken.decimals);
  }

  Logger.error('No fee information available for network fee calculation');
  return 0;
}

/// Check if a user has enough tokens to cover a fee
bool canUserCoverFee({
  required NetworkFeeOption? selectedFee,
  required ion.WalletAsset? networkNativeToken,
  double sendAmount = 0.0,
  bool isSendingNativeToken = false,
}) {
  if (networkNativeToken == null) return false;

  final parsedBalance = double.tryParse(networkNativeToken.balance) ?? 0;
  final convertedBalance = parsedBalance / pow(10, networkNativeToken.decimals);

  // Calculate total required amount
  final feeAmount = selectedFee?.amount ?? 0.0;
  final totalRequired = isSendingNativeToken ? feeAmount + sendAmount : feeAmount;

  if (selectedFee == null) return convertedBalance > (isSendingNativeToken ? sendAmount : 0);
  return convertedBalance >= totalRequired;
}

// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/extensions/object.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message/money_message_coin_resolver.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message/money_message_event_extractors.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message/money_message_models.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/utils/crypto.dart';

class MoneyMessageDisplayResolver {
  const MoneyMessageDisplayResolver({
    required MoneyMessageCoinResolver coinResolver,
  }) : _coinResolver = coinResolver;

  final MoneyMessageCoinResolver _coinResolver;

  Future<MoneyDisplayData?> resolveFundsRequestDisplayData(
    FundsRequestEntity fundsRequest,
  ) async {
    final resolved = await _resolveMoneyAmountData(
      assetId: fundsRequest.data.content.assetId?.emptyOrValue,
      networkId: fundsRequest.data.networkId,
      assetAddress: fundsRequest.data.assetAddress,
      rawAmount: fundsRequest.data.content.amount?.emptyOrValue,
      rawAmountIsBlockchainUnits: false,
    );

    return buildMoneyDisplayData(
      coin: resolved?.coin,
      amount: resolved?.amount,
    );
  }

  Future<MoneyDisplayData?> resolveMoneyDisplayDataFromPaymentSentTag(
    EventMessage eventMessage,
  ) async {
    final walletAssetEntity = paymentSentWalletAssetEntityFromMessage(eventMessage);
    if (walletAssetEntity == null) {
      return null;
    }

    return resolveMoneyDisplayDataFromWalletAsset(walletAssetEntity);
  }

  Future<MoneyDisplayData?> resolveMoneyDisplayDataFromWalletAsset(
    WalletAssetEntity walletAssetEntity,
  ) async {
    final resolved = await _resolveMoneyAmountData(
      assetId: walletAssetEntity.data.content.assetId?.emptyOrValue,
      networkId: walletAssetEntity.data.networkId,
      assetAddress: walletAssetEntity.data.assetAddress,
      rawAmount: walletAssetEntity.data.content.amount?.emptyOrValue,
      rawAmountIsBlockchainUnits: true,
    );

    return buildMoneyDisplayData(
      coin: resolved?.coin,
      amount: resolved?.amount,
    );
  }

  Future<MoneyMessageFallbackUiData?> resolveSentMoneyFallbackUiData(
    EventMessage eventMessage,
  ) async {
    final walletAssetEntity = paymentSentWalletAssetEntityFromMessage(eventMessage);
    if (walletAssetEntity == null) {
      return null;
    }

    final resolved = await _resolveMoneyAmountData(
      assetId: walletAssetEntity.data.content.assetId?.emptyOrValue,
      networkId: walletAssetEntity.data.networkId,
      assetAddress: walletAssetEntity.data.assetAddress,
      rawAmount: walletAssetEntity.data.content.amount?.emptyOrValue,
      rawAmountIsBlockchainUnits: true,
    );
    if (resolved == null) {
      return null;
    }

    final equivalentUsd = walletAssetEntity.data.content.amountUsd?.let(double.parse) ??
        (resolved.coin != null ? (resolved.amount ?? 0.0) * resolved.coin!.priceUSD : 0.0);

    return (
      coin: resolved.coin,
      amount: resolved.amount ?? 0.0,
      equivalentUsd: equivalentUsd,
      rawAmount: resolved.rawAmount,
      networkId: walletAssetEntity.data.networkId,
    );
  }

  MoneyDisplayData? buildMoneyDisplayData({
    required CoinData? coin,
    required double? amount,
  }) {
    if (coin == null || amount == null) {
      return null;
    }

    return (
      amount: formatCryptoFull(amount),
      coin: coin.abbreviation,
    );
  }

  Future<ResolvedMoneyAmountData?> _resolveMoneyAmountData({
    required String? assetId,
    required String networkId,
    required String assetAddress,
    required String? rawAmount,
    required bool rawAmountIsBlockchainUnits,
  }) async {
    final sanitizedRawAmount = rawAmount?.trim();
    if (sanitizedRawAmount == null || sanitizedRawAmount.isEmpty) {
      return null;
    }

    final coin = await _coinResolver.resolve(
      assetId: assetId,
      networkId: networkId,
      assetAddress: assetAddress,
    );

    final amount = switch ((coin, rawAmountIsBlockchainUnits)) {
      (final coinData?, true) => fromBlockchainUnits(
          sanitizedRawAmount,
          decimals: coinData.decimals,
        ),
      (_, false) => double.tryParse(sanitizedRawAmount),
      _ => null,
    };

    return (
      coin: coin,
      amount: amount,
      rawAmount: sanitizedRawAmount,
    );
  }
}

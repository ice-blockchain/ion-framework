// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message/money_message_coin_resolver.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message/money_message_display_resolver.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message/money_message_event_extractors.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message/money_message_models.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/wallets/data/repository/networks_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/request_assets_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_service.r.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'money_message_provider.r.g.dart';

@riverpod
Stream<FundsRequestEntity?> fundsRequestForMessage(
  Ref ref,
  EventMessage eventMessage,
) async* {
  final eventReference =
      EventReference.fromEncoded(eventMessage.content) as ImmutableEventReference;

  yield* switch (eventReference.kind) {
    FundsRequestEntity.kind =>
      ref.watch(requestAssetsRepositoryProvider).watchRequestAssetById(eventReference.eventId),
    _ => Stream.value(null),
  };
}

@riverpod
Future<FundsRequestEntity?> fundsRequestEntityForEventMessage(
  Ref ref,
  EventMessage eventMessage,
) async {
  // Try to extract 1755 (FundsRequestEntity) from "payment-requested" tag
  final requestEvent = eventMessageFromTag(
    eventMessage,
    ReplaceablePrivateDirectMessageData.paymentRequestedTagName,
  );
  if (requestEvent != null) {
    return FundsRequestEntity.fromEventMessage(requestEvent);
  }
  return ref.watch(fundsRequestForMessageProvider(eventMessage).future);
}

@riverpod
Future<MoneyDisplayData?> fundsRequestDisplayData(
  Ref ref,
  EventMessage eventMessage,
) async {
  final fundsRequest =
      await ref.watch(fundsRequestEntityForEventMessageProvider(eventMessage).future);
  if (fundsRequest == null) {
    return null;
  }

  final displayResolver = await ref.watch(moneyMessageDisplayResolverProvider.future);
  return displayResolver.resolveFundsRequestDisplayData(fundsRequest);
}

@riverpod
Stream<TransactionData?> transactionDataForMessage(
  Ref ref,
  EventMessage eventMessage,
) async* {
  final eventReference =
      EventReference.fromEncoded(eventMessage.content) as ImmutableEventReference;

  if (eventReference.kind != WalletAssetEntity.kind) {
    yield null;
    return;
  }

  final txHash = txHashFromPaymentSentTag(eventMessage);

  final transactionsRepository = await ref.watch(transactionsRepositoryProvider.future);

  if (txHash == null || txHash.isEmpty) {
    yield* transactionsRepository.watchTransactionByEventId(eventReference.eventId);
    return;
  }

  // Watch by txHash and externalHash separately and prefer txHash match over externalHash
  final byHash = transactionsRepository.watchTransactions(
    txHashes: [txHash],
    limit: 1,
  ).map((transactions) {
    final selected = pickBestTransaction(
      eventId: eventReference.eventId,
      txHash: txHash,
      transactions: transactions,
    );
    return selected;
  });

  final byExternalHash = transactionsRepository.watchTransactions(
    externalHashes: [txHash],
    limit: 1,
  ).map((transactions) {
    final selected = pickBestTransaction(
      eventId: eventReference.eventId,
      txHash: txHash,
      transactions: transactions,
    );
    return selected;
  });

  // Prefer txHash stream value when present, otherwise externalHash
  yield* Rx.combineLatest2<TransactionData?, TransactionData?, TransactionData?>(
    byHash.startWith(null),
    byExternalHash.startWith(null),
    (byTxHash, byExternal) => byTxHash ?? byExternal,
  );
}

@riverpod
Future<MoneyDisplayData?> transactionDisplayData(
  Ref ref,
  EventMessage eventMessage,
) async {
  final displayResolver = await ref.watch(moneyMessageDisplayResolverProvider.future);
  final fromEmbedded =
      await displayResolver.resolveMoneyDisplayDataFromPaymentSentTag(eventMessage);
  if (fromEmbedded != null) return fromEmbedded;

  final transactionData = await ref.watch(transactionDataForMessageProvider(eventMessage).future);

  if (transactionData == null) {
    return null;
  }

  final asset = transactionData.cryptoAsset.mapOrNull(coin: (asset) => asset);
  final coin = asset?.coin;

  final amount = asset?.amount;

  return displayResolver.buildMoneyDisplayData(
    coin: coin,
    amount: amount,
  );
}

@riverpod
Future<MoneyMessageDisplayResolver> moneyMessageDisplayResolver(Ref ref) async {
  final coinResolver = MoneyMessageCoinResolver(
    coinsService: await ref.watch(coinsServiceProvider.future),
    networksRepository: ref.watch(networksRepositoryProvider),
    ionIdentityClient: await ref.watch(ionIdentityClientProvider.future),
    tokenAnalyticsClient: await ref.watch(ionTokenAnalyticsClientProvider.future),
  );
  return MoneyMessageDisplayResolver(coinResolver: coinResolver);
}

@riverpod
Future<MoneyMessageFallbackUiData?> sentMoneyFallbackUiData(
  Ref ref,
  EventMessage eventMessage,
) async {
  final displayResolver = await ref.watch(moneyMessageDisplayResolverProvider.future);
  return displayResolver.resolveSentMoneyFallbackUiData(eventMessage);
}

@riverpod
Future<SentMoneyMessageUiData?> sentMoneyMessageUiData(
  Ref ref,
  EventMessage eventMessage,
) async {
  final transactionData = await ref.watch(transactionDataForMessageProvider(eventMessage).future);
  final txAsset = transactionData?.cryptoAsset.mapOrNull(coin: (asset) => asset);

  if (transactionData != null && txAsset != null) {
    return (
      transactionData: transactionData,
      network: transactionData.network,
      coin: txAsset.coin,
      amount: txAsset.amount,
      equivalentUsd: txAsset.amountUSD,
    );
  }

  final sentMoneyUiFallbackData =
      await ref.watch(sentMoneyFallbackUiDataProvider(eventMessage).future);
  if (sentMoneyUiFallbackData == null) {
    return null;
  }

  final network = await ref.watch(networkByIdProvider(sentMoneyUiFallbackData.networkId).future);

  return (
    transactionData: transactionData,
    network: network,
    coin: sentMoneyUiFallbackData.coin,
    amount: sentMoneyUiFallbackData.amount,
    equivalentUsd: sentMoneyUiFallbackData.equivalentUsd,
  );
}

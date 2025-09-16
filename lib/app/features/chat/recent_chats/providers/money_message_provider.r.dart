// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/extensions/object.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/wallets/data/repository/request_assets_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/providers/coins_provider.r.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_parser.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'money_message_provider.r.g.dart';

typedef MoneyDisplayData = ({String amount, String coin});

EventMessage? _eventFromTag(EventMessage source, String tagName) {
  try {
    final tag = source.tags.firstWhereOrNull(
      (t) => t.isNotEmpty && t.first == tagName,
    );
    if (tag != null && tag.length >= 2) {
      final decoded = jsonDecode(tag[1]) as Map<String, dynamic>;
      return EventMessage.fromPayloadJson(decoded);
    }
  } catch (e, stackTrace) {
    Logger.error(
      e,
      stackTrace: stackTrace,
      message: 'Failed to extract EventMessage from tag: $tagName',
    );
  }
  return null;
}

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
  final requestEvent = _eventFromTag(
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

  final assetId = fundsRequest.data.content.assetId?.emptyOrValue;
  final coin = await ref.watch(coinByIdProvider(assetId.emptyOrValue).future);
  final amount = fundsRequest.data.content.amount?.let(double.parse);

  if (coin == null || amount == null) {
    return null;
  }

  return (
    amount: formatCrypto(amount),
    coin: coin.abbreviation,
  );
}

@riverpod
Stream<TransactionData?> transactionDataForMessage(
  Ref ref,
  EventMessage eventMessage,
) async* {
  final eventReference =
      EventReference.fromEncoded(eventMessage.content) as ImmutableEventReference;

  yield* switch (eventReference.kind) {
    WalletAssetEntity.kind => ref
            .watch(transactionsRepositoryProvider)
            .valueOrNull
            ?.watchTransactionByEventId(eventReference.eventId) ??
        Stream.value(null),
    _ => Stream.value(null),
  };
}

@riverpod
Future<MoneyDisplayData?> transactionDisplayData(
  Ref ref,
  EventMessage eventMessage,
) async {
  // Try to extract 1756 (WalletAssetEntity) from "payment-sent" tag
  final walletAssetEvent = _eventFromTag(
    eventMessage,
    ReplaceablePrivateDirectMessageData.paymentSentTagName,
  );
  if (walletAssetEvent != null) {
    final walletAssetEntity = WalletAssetEntity.fromEventMessage(walletAssetEvent);

    final assetId = walletAssetEntity.data.content.assetId?.emptyOrValue;
    final rawAmount = walletAssetEntity.data.content.amount?.emptyOrValue;

    if (assetId != null && assetId.isNotEmpty && rawAmount != null && rawAmount.isNotEmpty) {
      final coin = await ref.watch(coinByIdProvider(assetId).future);
      if (coin != null) {
        final normalizedAmount = parseCryptoAmount(rawAmount, coin.decimals);
        return (
          amount: formatCrypto(normalizedAmount),
          coin: coin.abbreviation,
        );
      }
    }
  }

  final transactionData = await ref.watch(transactionDataForMessageProvider(eventMessage).future);

  if (transactionData == null) {
    return null;
  }

  final asset = transactionData.cryptoAsset.mapOrNull(coin: (asset) => asset);
  final coin = asset?.coin;

  final amount = asset?.amount;

  if (coin == null || amount == null) {
    return null;
  }

  return (
    amount: formatCrypto(amount),
    coin: coin.abbreviation,
  );
}

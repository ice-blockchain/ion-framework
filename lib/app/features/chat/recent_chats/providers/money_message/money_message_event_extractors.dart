// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/services/logger/logger.dart';

EventMessage? eventMessageFromTag(EventMessage source, String tagName) {
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

WalletAssetEntity? paymentSentWalletAssetEntityFromMessage(
  EventMessage eventMessage,
) {
  final walletAssetEvent = eventMessageFromTag(
    eventMessage,
    ReplaceablePrivateDirectMessageData.paymentSentTagName,
  );

  if (walletAssetEvent == null) {
    return null;
  }

  try {
    return WalletAssetEntity.fromEventMessage(walletAssetEvent);
  } catch (error, stackTrace) {
    Logger.error(
      error,
      stackTrace: stackTrace,
      message: 'Failed to parse wallet asset event for money message ${eventMessage.id}',
    );
    return null;
  }
}

/// Attempts to read the transaction hash from the "payment-sent" tag.
/// Returns null if the tag is missing or malformed.
String? txHashFromPaymentSentTag(EventMessage eventMessage) {
  return paymentSentWalletAssetEntityFromMessage(eventMessage)?.data.content.txHash;
}

/// Chooses the most relevant transaction when several candidates are returned.
TransactionData? pickBestTransaction({
  required String eventId,
  required String txHash,
  required List<TransactionData> transactions,
}) {
  if (transactions.isEmpty) {
    return null;
  }

  return transactions.firstWhereOrNull((t) => t.eventId == eventId) ??
      transactions.firstWhereOrNull((t) => t.externalHash == txHash) ??
      transactions.firstWhereOrNull((t) => t.txHash == txHash) ??
      transactions.firstOrNull;
}

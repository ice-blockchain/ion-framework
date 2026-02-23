// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/transaction_amount.f.dart';

part 'community_token_action.f.freezed.dart';

enum CommunityTokenActionType {
  buy,
  sell,
}

@Freezed(equal: false)
class CommunityTokenActionEntity
    with IonConnectEntity, CacheableEntity, ImmutableEntity, _$CommunityTokenActionEntity
    implements EntityEventSerializable {
  const factory CommunityTokenActionEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required CommunityTokenActionData data,
    EventMessage? eventMessage,
  }) = _CommunityTokenActionEntity;

  const CommunityTokenActionEntity._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/ICIP-11000.md#community-token-action-notification-event
  factory CommunityTokenActionEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return CommunityTokenActionEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: CommunityTokenActionData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  @override
  FutureOr<EventMessage> toEntityEventMessage() => eventMessage ?? toEventMessage(data);

  static const int kind = 1175;
}

@freezed
class CommunityTokenActionData with _$CommunityTokenActionData implements EventSerializable {
  const factory CommunityTokenActionData({
    required EventReference definitionReference,
    required String network,
    required String bondingCurveAddress,
    required String tokenAddress,
    required String transactionAddress,
    required CommunityTokenActionType type,
    required List<TransactionAmount> amounts,
    required List<RelatedHashtag> relatedHashtags,
    required RelatedPubkey relatedPubkey,
  }) = _CommunityTokenActionData;

  const CommunityTokenActionData._();

  factory CommunityTokenActionData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    final eventReference =
        (tags[ReplaceableEventReference.tagName] ?? tags[ImmutableEventReference.tagName])
            ?.map(EventReference.fromTag)
            .firstOrNull;

    final network = tags['network']?.firstOrNull?.lastOrNull;
    final bondingCurveAddress = tags['bonding_curve_address']?.firstOrNull?.lastOrNull;
    final tokenAddress = tags['token_address']?.firstOrNull?.lastOrNull;
    final transactionAddress = tags['tx_address']?.firstOrNull?.lastOrNull;
    final typeRaw = tags['tx_type']?.firstOrNull?.lastOrNull;
    final type = typeRaw != null
        ? CommunityTokenActionType.values.firstWhereOrNull((e) => e.name == typeRaw)
        : null;
    final amounts = tags[TransactionAmount.tagName]?.map(TransactionAmount.fromTag).toList();
    final relatedPubkey = tags[RelatedPubkey.tagName]?.map(RelatedPubkey.fromTag).firstOrNull;
    final relatedHashtags =
        tags[RelatedHashtag.tagName]?.map(RelatedHashtag.fromTag).toList() ?? [];

    if (eventReference == null ||
        network == null ||
        bondingCurveAddress == null ||
        tokenAddress == null ||
        transactionAddress == null ||
        typeRaw == null ||
        type == null ||
        amounts == null ||
        amounts.isEmpty ||
        relatedPubkey == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    return CommunityTokenActionData(
      definitionReference: eventReference,
      network: network,
      bondingCurveAddress: bondingCurveAddress,
      tokenAddress: tokenAddress,
      transactionAddress: transactionAddress,
      type: type,
      amounts: amounts,
      relatedHashtags: relatedHashtags,
      relatedPubkey: relatedPubkey,
    );
  }

  factory CommunityTokenActionData.fromData({
    /// Reference to the Community Token Definition event
    required EventReference definitionReference,

    /// Label / Name of the blockchain
    required String network,

    /// If the user already has a position in the token.
    ///
    /// It is used to mark the buy event, which is later used to calculate the HODL statistics.
    /// There might be multiple such buys for a user, e.g. if they bought, fully sold, and bought again.
    /// In this case the HODL resets.
    required bool hasUserPosition,

    /// Address of the bonding curve smart contract on the blockchain
    required String bondingCurveAddress,

    /// Address of the community token on the blockchain
    required String tokenAddress,

    /// Address of the specific transaction for that community token on the blockchain
    required String transactionAddress,

    /// Type of the transaction (buy/sell)
    required CommunityTokenActionType type,

    /// Amount in base currency (e.g. ETH)
    required TransactionAmount amountBase,

    /// Amount in quote currency (e.g. TOKEN)
    required TransactionAmount amountQuote,

    /// Amount in USD
    required TransactionAmount amountUsd,
  }) {
    if (amountUsd.currency != TransactionAmount.usdCurrency) {
      throw ArgumentError.value(
        amountUsd,
        'amountUsd',
        'The currency of amountUsd must be ${TransactionAmount.usdCurrency}',
      );
    }
    return CommunityTokenActionData(
      definitionReference: definitionReference,
      network: network,
      bondingCurveAddress: bondingCurveAddress,
      tokenAddress: tokenAddress,
      transactionAddress: transactionAddress,
      type: type,
      amounts: [amountBase, amountQuote, amountUsd],
      relatedHashtags: _buildRelatedHashtags(hasUserPosition: hasUserPosition, type: type),
      relatedPubkey: RelatedPubkey(value: definitionReference.masterPubkey),
    );
  }

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) async {
    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt,
      kind: CommunityTokenActionEntity.kind,
      content: '',
      tags: [
        ...tags,
        definitionReference.toTag(),
        ...relatedHashtags.map((hashtag) => hashtag.toTag()),
        ...amounts.map((amount) => amount.toTag()),
        relatedPubkey.toTag(),
        ['network', network],
        ['bonding_curve_address', bondingCurveAddress],
        ['token_address', tokenAddress],
        ['tx_address', transactionAddress],
        ['tx_type', type.name],
      ],
    );
  }

  TransactionAmount? getAmountByCurrency(String currency) {
    return amounts.firstWhereOrNull((amount) => amount.currency == currency);
  }

  static List<RelatedHashtag> _buildRelatedHashtags({
    required bool hasUserPosition,
    required CommunityTokenActionType type,
  }) {
    return [
      const RelatedHashtag(value: communityTokenTopic),
      const RelatedHashtag(value: communityTokenActionTopic),
      if (type == CommunityTokenActionType.buy && !hasUserPosition)
        const RelatedHashtag(value: communityTokenPositionResetTopic),
    ];
  }
}

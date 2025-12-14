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
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';

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
    required double amount,
    required double amountPriceUsd,
    required String currency,
    required List<RelatedHashtag> relatedHashtags,
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
    final amount = double.tryParse(tags['tx_amount']?.firstOrNull?.lastOrNull ?? '');
    final amountPriceUsd =
        double.tryParse(tags['tx_amount_price_usd']?.firstOrNull?.lastOrNull ?? '');
    final currency = tags['tx_currency']?.firstOrNull?.lastOrNull;

    if (eventReference == null ||
        network == null ||
        bondingCurveAddress == null ||
        tokenAddress == null ||
        transactionAddress == null ||
        typeRaw == null ||
        type == null ||
        amount == null ||
        amountPriceUsd == null ||
        currency == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    return CommunityTokenActionData(
      definitionReference: eventReference,
      network: network,
      bondingCurveAddress: bondingCurveAddress,
      tokenAddress: tokenAddress,
      transactionAddress: transactionAddress,
      type: type,
      amount: amount,
      amountPriceUsd: amountPriceUsd,
      currency: currency,
      relatedHashtags: _buildRelatedHashtags(),
    );
  }

  factory CommunityTokenActionData.fromData({
    required EventReference definitionReference,
    required String network,
    required String bondingCurveAddress,
    required String tokenAddress,
    required String transactionAddress,
    required CommunityTokenActionType type,
    required double amount,
    required double amountPriceUsd,
    required String currency,
  }) {
    return CommunityTokenActionData(
      definitionReference: definitionReference,
      network: network,
      bondingCurveAddress: bondingCurveAddress,
      tokenAddress: tokenAddress,
      transactionAddress: transactionAddress,
      type: type,
      amount: amount,
      amountPriceUsd: amountPriceUsd,
      currency: currency,
      relatedHashtags: _buildRelatedHashtags(),
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
        ['network', network],
        ['bonding_curve_address', bondingCurveAddress],
        ['token_address', tokenAddress],
        ['tx_address', transactionAddress],
        ['tx_type', type.name],
        ['tx_amount', amount.toString()],
        ['tx_amount_price_usd', amountPriceUsd.toString()],
        ['tx_currency', currency],
      ],
    );
  }

  static List<RelatedHashtag> _buildRelatedHashtags() {
    return [
      const RelatedHashtag(value: communityTokenTopic),
      const RelatedHashtag(value: communityTokenActionTopic),
    ];
  }
}

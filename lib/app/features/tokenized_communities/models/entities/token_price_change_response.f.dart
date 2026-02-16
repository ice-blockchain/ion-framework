// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_price_change_request.f.dart';

part 'token_price_change_response.f.freezed.dart';

@Freezed(equal: false)
class TokenPriceChangeResponseEntity
    with _$TokenPriceChangeResponseEntity, IonConnectEntity, ImmutableEntity, CacheableEntity {
  const factory TokenPriceChangeResponseEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required TokenPriceChangeResponseData data,
  }) = _TokenPriceChangeResponseEntity;

  const TokenPriceChangeResponseEntity._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/dvm/ICIP-5176.md
  factory TokenPriceChangeResponseEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return TokenPriceChangeResponseEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: TokenPriceChangeResponseData.fromEventMessage(eventMessage),
    );
  }

  static const int kind = 6176;
}

@freezed
class TokenPriceChangeResponseData with _$TokenPriceChangeResponseData {
  const factory TokenPriceChangeResponseData({
    required TokenPriceChangeRequestEntity request,
    required ReplaceableEventReference tokenDefinitionReference,
    required List<CommunityTokenActionEntity> actions,
  }) = _TokenPriceChangeResponseData;

  const TokenPriceChangeResponseData._();

  factory TokenPriceChangeResponseData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    return TokenPriceChangeResponseData(
      request: TokenPriceChangeRequestEntity.fromEventMessage(
        EventMessage.fromPayloadJson(jsonDecode(tags['request']!.first[1]) as Map<String, dynamic>),
      ),
      tokenDefinitionReference:
          ReplaceableEventReference.fromTag(tags[ReplaceableEventReference.tagName]!.first),
      actions: (jsonDecode(eventMessage.content) as List<dynamic>)
          .map(
            (action) => CommunityTokenActionEntity.fromEventMessage(
              EventMessage.fromPayloadJson(action as Map<String, dynamic>),
            ),
          )
          .toList(),
    );
  }
}

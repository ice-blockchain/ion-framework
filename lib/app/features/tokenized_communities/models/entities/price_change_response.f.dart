// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/price_change_request.f.dart';

part 'price_change_response.f.freezed.dart';

@Freezed(equal: false)
class PriceChangeResponseEntity
    with _$PriceChangeResponseEntity, IonConnectEntity, ImmutableEntity, CacheableEntity {
  const factory PriceChangeResponseEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required PriceChangeResponseData data,
  }) = _PriceChangeResponseEntity;

  const PriceChangeResponseEntity._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/dvm/ICIP-5176.md
  factory PriceChangeResponseEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return PriceChangeResponseEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: PriceChangeResponseData.fromEventMessage(eventMessage),
    );
  }

  static const int kind = 6176;
}

@freezed
class PriceChangeResponseData with _$PriceChangeResponseData {
  const factory PriceChangeResponseData({
    required PriceChangeRequestEntity request,
    required PriceChangeInput input,
    required List<CommunityTokenActionEntity> actions,
  }) = _PriceChangeResponseData;

  const PriceChangeResponseData._();

  factory PriceChangeResponseData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    return PriceChangeResponseData(
      request: PriceChangeRequestEntity.fromEventMessage(
        EventMessage.fromPayloadJson(jsonDecode(tags['request']!.first[1]) as Map<String, dynamic>),
      ),
      input: PriceChangeInput.fromTags(tags[PriceChangeInput.tagName] ?? []),
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

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
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_price_change_request.f.dart';

part 'tokens_global_stat_response.f.freezed.dart';

@Freezed(equal: false)
class TokenGlobalStatResponseEntity
    with _$TokenGlobalStatResponseEntity, IonConnectEntity, ImmutableEntity, CacheableEntity {
  const factory TokenGlobalStatResponseEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required TokenGlobalStatResponseData data,
  }) = _TokenGlobalStatResponseEntity;

  const TokenGlobalStatResponseEntity._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/dvm/ICIP-5177.md
  factory TokenGlobalStatResponseEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return TokenGlobalStatResponseEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: TokenGlobalStatResponseData.fromEventMessage(eventMessage),
    );
  }

  static const int kind = 6177;
}

@freezed
class TokenGlobalStatResponseData with _$TokenGlobalStatResponseData {
  const factory TokenGlobalStatResponseData({
    required TokenPriceChangeRequestEntity request,
    required CommunityTokenDefinitionEntity tokenDefinition,
    required List<IonConnectEntity> entities,
  }) = _TokenGlobalStatResponseData;

  const TokenGlobalStatResponseData._();

  factory TokenGlobalStatResponseData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final tokenDefinitionReference =
        ReplaceableEventReference.fromTag(tags[ReplaceableEventReference.tagName]!.first);

    final request = TokenPriceChangeRequestEntity.fromEventMessage(
      EventMessage.fromPayloadJson(jsonDecode(tags['request']!.first[1]) as Map<String, dynamic>),
    );

    final entities = (jsonDecode(eventMessage.content) as List<dynamic>)
        .map(
          (event) {
            final eventMessage = EventMessage.fromPayloadJson(event as Map<String, dynamic>);
            return switch (eventMessage.kind) {
              CommunityTokenActionEntity.kind =>
                CommunityTokenActionEntity.fromEventMessage(eventMessage),
              CommunityTokenDefinitionEntity.kind =>
                CommunityTokenDefinitionEntity.fromEventMessage(eventMessage),
              _ => null,
            };
          },
        )
        .nonNulls
        .toList();

    final tokenDefinition = entities
        .whereType<CommunityTokenDefinitionEntity>()
        .firstWhereOrNull((entity) => entity.toEventReference() == tokenDefinitionReference);

    if (tokenDefinition == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    return TokenGlobalStatResponseData(
      request: request,
      tokenDefinition: tokenDefinition,
      entities: entities,
    );
  }
}

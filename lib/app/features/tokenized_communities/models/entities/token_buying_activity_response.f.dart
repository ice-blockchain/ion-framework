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
import 'package:ion/app/features/tokenized_communities/models/entities/token_buying_activity_request.f.dart';
import 'package:ion/app/features/tokenized_communities/utils/timeframe_extension.dart';

part 'token_buying_activity_response.f.freezed.dart';

@Freezed(equal: false)
class TokenBuyingActivityResponseEntity
    with _$TokenBuyingActivityResponseEntity, IonConnectEntity, ImmutableEntity, CacheableEntity {
  const factory TokenBuyingActivityResponseEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required TokenBuyingActivityResponseData data,
  }) = _TokenBuyingActivityResponseEntity;

  const TokenBuyingActivityResponseEntity._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/dvm/ICIP-5178.md
  factory TokenBuyingActivityResponseEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return TokenBuyingActivityResponseEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: TokenBuyingActivityResponseData.fromEventMessage(eventMessage),
    );
  }

  static const int kind = 6178;
}

@freezed
class TokenBuyingActivityResponseData with _$TokenBuyingActivityResponseData {
  const factory TokenBuyingActivityResponseData({
    required TokenBuyingActivityRequestEntity request,
    required CommunityTokenDefinitionEntity tokenDefinition,
    required List<IonConnectEntity> entities,
    required TokenBuyingActivity buyingActivity,
  }) = _TokenBuyingActivityResponseData;

  const TokenBuyingActivityResponseData._();

  factory TokenBuyingActivityResponseData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final tokenDefinitionReference =
        ReplaceableEventReference.fromTag(tags[ReplaceableEventReference.tagName]!.first);

    final request = TokenBuyingActivityRequestEntity.fromEventMessage(
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

    final buyingActivity = TokenBuyingActivity.fromTag(tags[TokenBuyingActivity.tagName]!.first);

    return TokenBuyingActivityResponseData(
      request: request,
      tokenDefinition: tokenDefinition,
      entities: entities,
      buyingActivity: buyingActivity,
    );
  }
}

@freezed
class TokenBuyingActivity with _$TokenBuyingActivity {
  const factory TokenBuyingActivity({
    required int userCount,
    required Duration timePeriod,
  }) = _TokenBuyingActivity;

  const TokenBuyingActivity._();

  factory TokenBuyingActivity.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length < 3) {
      throw IncorrectEventTagException(tag: tag.toString());
    }
    final userCount = int.tryParse(tag[1]);

    if (userCount == null) {
      throw IncorrectEventTagException(tag: tag[1]);
    }

    final duration = tag[2].duration;
    return TokenBuyingActivity(userCount: userCount, timePeriod: duration);
  }

  static const String tagName = 'buying-activity';
}

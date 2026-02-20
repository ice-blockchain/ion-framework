// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/related_relay.f.dart';
import 'package:ion/app/features/ion_connect/model/related_token.f.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/push_notifications/data/models/push_subscription_platform.f.dart';

part 'push_subscription.f.freezed.dart';

@Freezed(equal: false)
class PushSubscriptionEntity
    with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$PushSubscriptionEntity {
  const factory PushSubscriptionEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required PushSubscriptionData data,
    EventMessage? eventMessage,
  }) = _PushSubscriptionEntity;

  const PushSubscriptionEntity._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/ICIP-8000.md#registering-device-tokens
  factory PushSubscriptionEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return PushSubscriptionEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: PushSubscriptionData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  static const int kind = 31751;
}

@freezed
class PushSubscriptionData
    with _$PushSubscriptionData
    implements EventSerializable, ReplaceableEntityData {
  const factory PushSubscriptionData({
    required String deviceId,
    required PushSubscriptionPlatform platform,
    required RelatedRelay relay,
    required RelatedToken fcmToken,
    required List<RequestFilter> filters,
  }) = _PushSubscriptionData;

  const PushSubscriptionData._();

  factory PushSubscriptionData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    return PushSubscriptionData(
      deviceId: tags[ReplaceableEventIdentifier.tagName]!
          .map(ReplaceableEventIdentifier.fromTag)
          .first
          .value,
      platform: tags[PushSubscriptionPlatform.tagName]!.map(PushSubscriptionPlatform.fromTag).first,
      relay: tags[RelatedRelay.tagName]!.map(RelatedRelay.fromTag).first,
      fcmToken: tags[RelatedToken.tagName]!.map(RelatedToken.fromTag).first,
      filters: (jsonDecode(eventMessage.content) as List<dynamic>)
          .map<RequestFilter>(
            (filterJson) => RequestFilter.fromJson(filterJson as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) {
    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt,
      kind: PushSubscriptionEntity.kind,
      content: jsonEncode(filters),
      tags: [
        ...tags,
        [ReplaceableEventIdentifier.tagName, deviceId],
        relay.toTag(),
        fcmToken.toTag(),
        platform.toTag(),
      ],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: PushSubscriptionEntity.kind,
      masterPubkey: pubkey,
      dTag: deviceId,
    );
  }
}

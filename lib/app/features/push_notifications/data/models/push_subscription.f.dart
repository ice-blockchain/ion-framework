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
    );
  }

  static const int kind = 31751;
}

abstract class PushSubscriptionData implements ReplaceableEntityData, EventSerializable {
  const PushSubscriptionData();

  factory PushSubscriptionData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    final filters = (jsonDecode(eventMessage.content) as List<dynamic>)
        .map<RequestFilter>(
          (filterJson) => RequestFilter.fromJson(filterJson as Map<String, dynamic>),
        )
        .toList();

    if (tags.containsKey(RelatedToken.tagName)) {
      final dTag = tags[ReplaceableEventIdentifier.tagName]!
          .map(ReplaceableEventIdentifier.fromTag)
          .first
          .value;
      return PushSubscriptionOwnData(
        deviceId: dTag,
        platform:
            tags[PushSubscriptionPlatform.tagName]!.map(PushSubscriptionPlatform.fromTag).first,
        relay: tags[RelatedRelay.tagName]!.map(RelatedRelay.fromTag).first,
        fcmToken: tags[RelatedToken.tagName]!.map(RelatedToken.fromTag).first,
        filters: filters,
      );
    } else {
      final dTag = tags[ReplaceableEventIdentifier.tagName]!
          .map(PushSubscriptionExternalDataDTag.fromTag)
          .first;
      return PushSubscriptionExternalData(
        dTag: dTag,
        relays: tags[RelatedRelay.tagName]!.map(RelatedRelay.fromTag).toList(),
        filters: filters,
      );
    }
  }

  List<RequestFilter> get filters;
}

/// Base push subscription data - it contains filters for ALL events
/// the user wants to receive, along with device data required
/// to register a device for push notifications.
///
/// This event is published to the own user relay.
@freezed
class PushSubscriptionOwnData with _$PushSubscriptionOwnData implements PushSubscriptionData {
  const factory PushSubscriptionOwnData({
    required String deviceId,
    required PushSubscriptionPlatform platform,
    required RelatedRelay relay,
    required RelatedToken fcmToken,
    required List<RequestFilter> filters,
  }) = _PushSubscriptionOwnData;

  const PushSubscriptionOwnData._();

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

/// Push subscription data for external accounts - it contains
/// filters only for the events that user wants to be notified about
/// from a specific external user.
///
/// It doesn't contain fcm token or platform info, as those are already
/// registered via the own push subscription event.
/// It has to have multiple relay tags, one for each relay the current user has.
/// This event is published to the relays of the external user, wrapped with 21750.
@freezed
class PushSubscriptionExternalData
    with _$PushSubscriptionExternalData
    implements PushSubscriptionData {
  const factory PushSubscriptionExternalData({
    required PushSubscriptionExternalDataDTag dTag,
    required List<RequestFilter> filters,
    required List<RelatedRelay> relays,
  }) = _PushSubscriptionExternalData;

  const PushSubscriptionExternalData._();

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
        dTag.toTag(),
        ...relays.map((relay) => relay.toTag()),
      ],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: PushSubscriptionEntity.kind,
      masterPubkey: pubkey,
      dTag: dTag.toString(),
    );
  }
}

@Freezed(toStringOverride: false)
class PushSubscriptionExternalDataDTag with _$PushSubscriptionExternalDataDTag {
  const factory PushSubscriptionExternalDataDTag({
    required String deviceId,
    required String externalUserMasterPubkey,
  }) = _PushSubscriptionExternalDataDTag;

  const PushSubscriptionExternalDataDTag._();

  factory PushSubscriptionExternalDataDTag.fromTag(List<String> tag) {
    if (tag[0] != ReplaceableEventIdentifier.tagName) {
      throw IncorrectEventTagNameException(
        actual: tag[0],
        expected: ReplaceableEventIdentifier.tagName,
      );
    }
    if (tag.length != 2) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return PushSubscriptionExternalDataDTag.fromString(tag[1]);
  }

  factory PushSubscriptionExternalDataDTag.fromString(String input) {
    final parts = input.split(PushSubscriptionExternalDataDTag.divider);
    if (parts.length != 2) {
      throw IncorrectEventTagException(tag: input);
    }

    return PushSubscriptionExternalDataDTag(
      externalUserMasterPubkey: parts[0],
      deviceId: parts[1],
    );
  }

  List<String> toTag() {
    return [ReplaceableEventIdentifier.tagName, toString()];
  }

  @override
  String toString() {
    return '$externalUserMasterPubkey${PushSubscriptionExternalDataDTag.divider}$deviceId';
  }

  static const String divider = '_';
}

// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';

part 'price_change_request.f.freezed.dart';

@Freezed(equal: false)
class PriceChangeRequestEntity
    with _$PriceChangeRequestEntity, IonConnectEntity, ImmutableEntity, CacheableEntity {
  const factory PriceChangeRequestEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required PriceChangeRequestData data,
  }) = _PriceChangeRequestEntity;

  const PriceChangeRequestEntity._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/dvm/ICIP-5176.md
  factory PriceChangeRequestEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return PriceChangeRequestEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: PriceChangeRequestData.fromEventMessage(eventMessage),
    );
  }

  static const int kind = 5176;
}

@freezed
class PriceChangeRequestData with _$PriceChangeRequestData implements EventSerializable {
  const factory PriceChangeRequestData({
    required PriceChangeInput input,
    required PriceChangeRequestParams params,
    String? output,
  }) = _PriceChangeRequestData;

  const PriceChangeRequestData._();

  factory PriceChangeRequestData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    return PriceChangeRequestData(
      input: PriceChangeInput.fromTags(tags[PriceChangeInput.tagName] ?? []),
      params: PriceChangeRequestParams.fromTags(tags[PriceChangeRequestParams.tagName] ?? []),
      output: tags['output']?.firstOrNull?[1],
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
      kind: PriceChangeRequestEntity.kind,
      content: '',
      tags: [
        ...tags,
        ...input.toTags(),
        ...params.toTags(),
      ],
    );
  }
}

@freezed
class PriceChangeRequestParams with _$PriceChangeRequestParams {
  const factory PriceChangeRequestParams({
    required int timeWindow,
    required int deltaPercentage,
  }) = _PriceChangeRequestParams;

  const PriceChangeRequestParams._();

  factory PriceChangeRequestParams.fromTags(List<List<String>> tags) {
    int? timeWindow;
    int? deltaPercentage;
    for (final tag in tags) {
      if (tag[0] == tagName) {
        if (tag.length != 3) {
          throw IncorrectEventTagException(tag: tag.toString());
        }
        if (tag[1] == 'timeWindow') timeWindow = int.tryParse(tag[2]);
        if (tag[1] == 'deltaPercentage') deltaPercentage = int.tryParse(tag[2]);
      }
    }

    if (timeWindow == null || deltaPercentage == null) {
      throw IncorrectEventTagException(tag: tags.toString());
    }

    return PriceChangeRequestParams(
      timeWindow: timeWindow,
      deltaPercentage: deltaPercentage,
    );
  }

  List<List<String>> toTags() {
    return [
      [tagName, 'timeWindow', timeWindow.toString()],
      [tagName, 'deltaPercentage', deltaPercentage.toString()],
    ];
  }

  static const String tagName = 'param';
}

@freezed
class PriceChangeInput with _$PriceChangeInput {
  const factory PriceChangeInput({
    required EventReference eventReference,
  }) = _PriceChangeInput;

  const PriceChangeInput._();

  factory PriceChangeInput.fromTags(List<List<String>> tags) {
    final tag = tags.firstWhereOrNull(
      (tag) => tag[0] == PriceChangeInput.tagName && tag.length == 5 && tag[4] == 'priceChange',
    );

    if (tag == null) {
      throw IncorrectEventTagException(tag: tag);
    }

    return PriceChangeInput(
      eventReference: ReplaceableEventReference.fromString(tag[1]),
    );
  }

  List<List<String>> toTags() {
    return [
      [tagName, eventReference.toString(), 'event', '', 'priceChange'],
    ];
  }

  static const String tagName = 'i';
}

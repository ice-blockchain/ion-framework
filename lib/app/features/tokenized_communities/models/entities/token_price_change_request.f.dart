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

part 'token_price_change_request.f.freezed.dart';

@Freezed(equal: false)
class TokenPriceChangeRequestEntity
    with _$TokenPriceChangeRequestEntity, IonConnectEntity, ImmutableEntity, CacheableEntity {
  const factory TokenPriceChangeRequestEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required TokenPriceChangeRequestData data,
  }) = _TokenPriceChangeRequestEntity;

  const TokenPriceChangeRequestEntity._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/dvm/ICIP-5176.md
  factory TokenPriceChangeRequestEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return TokenPriceChangeRequestEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: TokenPriceChangeRequestData.fromEventMessage(eventMessage),
    );
  }

  static const int kind = 5176;
}

@freezed
class TokenPriceChangeRequestData with _$TokenPriceChangeRequestData implements EventSerializable {
  const factory TokenPriceChangeRequestData({
    required TokenPriceChangeInput input,
    required TokenPriceChangeRequestParams params,
    String? output,
  }) = _TokenPriceChangeRequestData;

  const TokenPriceChangeRequestData._();

  factory TokenPriceChangeRequestData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    return TokenPriceChangeRequestData(
      input: TokenPriceChangeInput.fromTags(tags[TokenPriceChangeInput.tagName] ?? []),
      params:
          TokenPriceChangeRequestParams.fromTags(tags[TokenPriceChangeRequestParams.tagName] ?? []),
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
      kind: TokenPriceChangeRequestEntity.kind,
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
class TokenPriceChangeRequestParams with _$TokenPriceChangeRequestParams {
  const factory TokenPriceChangeRequestParams({
    required int timeWindow,
    required int deltaPercentage,
  }) = _TokenPriceChangeRequestParams;

  const TokenPriceChangeRequestParams._();

  factory TokenPriceChangeRequestParams.fromTags(List<List<String>> tags) {
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

    return TokenPriceChangeRequestParams(
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
class TokenPriceChangeInput with _$TokenPriceChangeInput {
  const factory TokenPriceChangeInput({
    required EventReference eventReference,
  }) = _TokenPriceChangeInput;

  const TokenPriceChangeInput._();

  factory TokenPriceChangeInput.fromTags(List<List<String>> tags) {
    final tag = tags.firstWhereOrNull(
      (tag) =>
          tag[0] == TokenPriceChangeInput.tagName && tag.length == 5 && tag[4] == 'priceChange',
    );

    if (tag == null) {
      throw IncorrectEventTagException(tag: tag);
    }

    return TokenPriceChangeInput(
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

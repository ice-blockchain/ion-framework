// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/output_tag.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_input.f.dart';

part 'token_buying_activity_request.f.freezed.dart';

@Freezed(equal: false)
class TokenBuyingActivityRequestEntity
    with _$TokenBuyingActivityRequestEntity, IonConnectEntity, ImmutableEntity, CacheableEntity {
  const factory TokenBuyingActivityRequestEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required TokenBuyingActivityRequestData data,
  }) = _TokenBuyingActivityRequestEntity;

  const TokenBuyingActivityRequestEntity._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/dvm/ICIP-5178.md
  factory TokenBuyingActivityRequestEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return TokenBuyingActivityRequestEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: TokenBuyingActivityRequestData.fromEventMessage(eventMessage),
    );
  }

  static const int kind = 5178;
}

@freezed
class TokenBuyingActivityRequestData
    with _$TokenBuyingActivityRequestData
    implements EventSerializable {
  const factory TokenBuyingActivityRequestData({
    required TokenBuyingActivityRequestParams params,
    @Default(MimeType.json) MimeType output,
  }) = _TokenBuyingActivityRequestData;

  const TokenBuyingActivityRequestData._();

  factory TokenBuyingActivityRequestData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final output = tags[OutputTag.tagName]!.map(OutputTag.fromTag).first.value;

    return TokenBuyingActivityRequestData(
      params: TokenBuyingActivityRequestParams.fromTags(
        tags[TokenBuyingActivityRequestParams.tagName] ?? [],
      ),
      output: output,
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
      kind: TokenBuyingActivityRequestEntity.kind,
      content: '',
      tags: [
        ...tags,
        ...params.toTags(),
        const TokenInputTag(value: TokenInput.inspectTokenBuyingActivity).toTag(),
        OutputTag(value: output).toTag(),
      ],
    );
  }
}

@freezed
class TokenBuyingActivityRequestParams with _$TokenBuyingActivityRequestParams {
  const factory TokenBuyingActivityRequestParams({
    required String authorMasterPubkey,
  }) = _TokenBuyingActivityRequestParams;

  const TokenBuyingActivityRequestParams._();

  factory TokenBuyingActivityRequestParams.fromTags(List<List<String>> tags) {
    String? authorMasterPubkey;
    for (final tag in tags) {
      if (tag[0] == tagName) {
        if (tag.length != 3) {
          throw IncorrectEventTagException(tag: tag.toString());
        }
        if (tag[1] == 'author') authorMasterPubkey = tag[2];
      }
    }

    if (authorMasterPubkey == null) {
      throw IncorrectEventTagException(tag: tags.toString());
    }

    return TokenBuyingActivityRequestParams(
      authorMasterPubkey: authorMasterPubkey,
    );
  }

  List<List<String>> toTags() {
    return [
      [tagName, 'author', authorMasterPubkey],
    ];
  }

  static const String tagName = 'param';
}

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

part 'tokens_global_stat_request.f.freezed.dart';

@Freezed(equal: false)
class TokensGlobalStatRequestEntity
    with _$TokensGlobalStatRequestEntity, IonConnectEntity, ImmutableEntity, CacheableEntity {
  const factory TokensGlobalStatRequestEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required TokensGlobalStatRequestData data,
  }) = _TokensGlobalStatRequestEntity;

  const TokensGlobalStatRequestEntity._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/dvm/ICIP-5177.md
  factory TokensGlobalStatRequestEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return TokensGlobalStatRequestEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: TokensGlobalStatRequestData.fromEventMessage(eventMessage),
    );
  }

  static const int kind = 5177;
}

@freezed
class TokensGlobalStatRequestData with _$TokensGlobalStatRequestData implements EventSerializable {
  const factory TokensGlobalStatRequestData({
    @Default(MimeType.json) MimeType output,
  }) = _TokensGlobalStatRequestData;

  const TokensGlobalStatRequestData._();

  factory TokensGlobalStatRequestData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final output = tags[OutputTag.tagName]!.map(OutputTag.fromTag).first.value;
    return TokensGlobalStatRequestData(
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
      kind: TokensGlobalStatRequestEntity.kind,
      content: '',
      tags: [
        ...tags,
        const TokenInputTag(value: TokenInput.trending).toTag(),
        OutputTag(value: output).toTag(),
      ],
    );
  }
}

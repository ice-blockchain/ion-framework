// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/dvm_response_entity.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

part 'dvm_error_entity.f.freezed.dart';

@Freezed(equal: false)
class DvmErrorEntity
    with _$DvmErrorEntity, IonConnectEntity, ImmutableEntity
    implements DvmResponseEntity {
  const factory DvmErrorEntity({
    required String id,
    required String pubkey,
    required String signature,
    required String masterPubkey,
    required int createdAt,
    required DvmErrorData data,
  }) = _DvmErrorEntity;

  const DvmErrorEntity._();

  factory DvmErrorEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    final data = DvmErrorData.fromEventMessage(eventMessage);

    return DvmErrorEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      signature: eventMessage.sig!,
      masterPubkey: eventMessage.masterPubkey,
      createdAt: eventMessage.createdAt,
      data: data,
    );
  }

  @override
  ImmutableEventReference get requestEventReference => data.requestEventReference;

  static const int kind = 7000;
}

@freezed
class DvmErrorData with _$DvmErrorData {
  const factory DvmErrorData({
    required String status,
    required int expiration,
    required ImmutableEventReference requestEventReference,
    required String pubkey,
    required String masterPubkey,
    required dynamic content,
  }) = _DvmErrorData;

  const DvmErrorData._();

  factory DvmErrorData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    final status = tags['status']?.firstOrNull?[1];
    final expirationTag = tags['expiration']?.firstOrNull?[1];
    final requestEventId = tags['e']?.firstOrNull?[1];
    final pubkey = tags['p']?.firstOrNull?[1];
    final masterPubkey = tags[MasterPubkeyTag.tagName]?.firstOrNull?[1];

    if (status == null ||
        expirationTag == null ||
        requestEventId == null ||
        pubkey == null ||
        masterPubkey == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    final expiration = int.tryParse(expirationTag);
    if (expiration == null) {
      throw IncorrectEventTagsException(eventId: eventMessage.id);
    }

    return DvmErrorData(
      status: status,
      expiration: expiration,
      requestEventReference: ImmutableEventReference(eventId: requestEventId, masterPubkey: pubkey),
      pubkey: pubkey,
      masterPubkey: masterPubkey,
      content: eventMessage.content,
    );
  }
}

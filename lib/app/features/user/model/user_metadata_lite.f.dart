// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';

part 'user_metadata_lite.f.freezed.dart';
part 'user_metadata_lite.f.g.dart';

@Freezed(equal: false)
class UserMetadataLiteEntity
    with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$UserMetadataLiteEntity
    implements EntityEventSerializable, DbCacheableEntity {
  const factory UserMetadataLiteEntity({
    required String masterPubkey,
    required UserMetadataLite data,
    @Default('') String id,
    @Default('') String pubkey,
    @Default('') String signature,
    @Default(0) int createdAt,
  }) = _UserMetadataLiteEntity;

  const UserMetadataLiteEntity._();

  factory UserMetadataLiteEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return UserMetadataLiteEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: UserMetadataLite.fromEventMessage(eventMessage),
    );
  }

  @override
  FutureOr<EventMessage> toEntityEventMessage() => toEventMessage(data);

  // Negative kind to indicate that this model is not part of the protocol and should be used only on the FE
  static const int kind = -1;
}

@freezed
class UserMetadataLite
    with _$UserMetadataLite
    implements EventSerializable, ReplaceableEntityData, UserPreviewData {
  const factory UserMetadataLite({
    required String name,
    required String displayName,
    String? picture,
  }) = _UserMetadataLite;

  factory UserMetadataLite.fromEventMessage(EventMessage eventMessage) {
    final userDataContent = UserDataLiteEventMessageContent.fromJson(
      json.decode(eventMessage.content) as Map<String, dynamic>,
    );
    return UserMetadataLite(
      name: userDataContent.name,
      displayName: userDataContent.displayName,
      picture: userDataContent.picture,
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
      kind: UserMetadataLiteEntity.kind,
      content: jsonEncode(
        UserDataLiteEventMessageContent(
          name: name,
          picture: picture,
          displayName: displayName,
        ).toJson(),
      ),
      tags: [
        ...tags,
      ],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: UserMetadataLiteEntity.kind,
      masterPubkey: pubkey,
    );
  }
}

@JsonSerializable(createToJson: true, includeIfNull: false)
class UserDataLiteEventMessageContent {
  UserDataLiteEventMessageContent({
    required this.name,
    required this.displayName,
    this.picture,
  });

  factory UserDataLiteEventMessageContent.fromJson(Map<String, dynamic> json) =>
      _$UserDataLiteEventMessageContentFromJson(json);

  final String name;

  final String displayName;

  final String? picture;

  Map<String, dynamic> toJson() => _$UserDataLiteEventMessageContentToJson(this);
}

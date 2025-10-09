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
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';

part 'user_metadata.f.freezed.dart';
part 'user_metadata.f.g.dart';

@Freezed(equal: false)
class UserMetadataEntity
    with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$UserMetadataEntity
    implements EntityEventSerializable, DbCacheableEntity {
  const factory UserMetadataEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required UserMetadata data,
  }) = _UserMetadataEntity;

  const UserMetadataEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/01.md#kinds
  factory UserMetadataEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return UserMetadataEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: UserMetadata.fromEventMessage(eventMessage),
    );
  }

  @override
  FutureOr<EventMessage> toEntityEventMessage() => toEventMessage(data);

  static const int kind = 0;

  static const locationCharacterLimit = 30;
  static const websiteCharacterLimit = 100;
}

@freezed
class UserMetadata with _$UserMetadata implements EventSerializable, ReplaceableEntityData {
  const factory UserMetadata({
    @Default('') String name,
    @Default('') String displayName,
    String? about,
    String? picture,
    String? website,
    String? location,
    String? category,
    int? registeredAt,
    String? banner,
    @Default({}) Map<String, MediaAttachment> media,
    Map<String, String>? wallets,
    WhoCanSetting? whoCanMessageYou,
    WhoCanSetting? whoCanInviteYouToGroups,
    Map<String, IonContentNftCollection>? ionContentNftCollections,
  }) = _UserMetadata;

  factory UserMetadata.fromEventMessage(EventMessage eventMessage) {
    final userDataContent = UserDataEventMessageContent.fromJson(
      json.decode(eventMessage.content) as Map<String, dynamic>,
    );

    final media = eventMessage.tags.fold(<String, MediaAttachment>{}, (res, tag) {
      if (tag[0] == MediaAttachment.tagName) {
        final attachment = MediaAttachment.fromTag(tag);
        return {...res, attachment.url: attachment};
      }
      return res;
    });

    return UserMetadata(
      name: userDataContent.name ?? '',
      displayName: userDataContent.displayName ?? '',
      about: userDataContent.about,
      picture: userDataContent.picture,
      website: userDataContent.website,
      banner: userDataContent.banner,
      location: userDataContent.location,
      category: userDataContent.category,
      registeredAt: userDataContent.registeredAt,
      media: media,
      whoCanMessageYou: WhoCanSetting.fromString(userDataContent.whoCanMessageYou),
      whoCanInviteYouToGroups: WhoCanSetting.fromString(userDataContent.whoCanInviteYouToGroups),
      wallets: userDataContent.wallets,
      ionContentNftCollections: userDataContent.ionContentNftCollections,
    );
  }

  const UserMetadata._();

  String? get avatarUrl =>
      media.values.where((element) => picture == element.url).firstOrNull?.thumb ?? picture;

  String get trimmedDisplayName => displayName.trim();

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) {
    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt,
      kind: UserMetadataEntity.kind,
      content: jsonEncode(
        UserDataEventMessageContent(
          name: name,
          about: about,
          picture: picture,
          displayName: displayName,
          website: website,
          banner: banner,
          location: location,
          category: category,
          registeredAt: registeredAt,
          whoCanMessageYou: whoCanMessageYou?.name,
          whoCanInviteYouToGroups: whoCanInviteYouToGroups?.name,
          wallets: wallets,
          ionContentNftCollections: ionContentNftCollections,
        ).toJson(),
      ),
      tags: [
        ...tags,
        for (final attachment in media.values) attachment.toTag(),
      ],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: UserMetadataEntity.kind,
      masterPubkey: pubkey,
    );
  }
}

@JsonSerializable(createToJson: true, includeIfNull: false)
class UserDataEventMessageContent {
  UserDataEventMessageContent({
    this.name,
    this.about,
    this.picture,
    this.displayName,
    this.website,
    this.location,
    this.category,
    this.registeredAt,
    this.banner,
    this.whoCanMessageYou,
    this.whoCanInviteYouToGroups,
    this.wallets,
    this.ionContentNftCollections,
  });

  factory UserDataEventMessageContent.fromJson(Map<String, dynamic> json) =>
      _$UserDataEventMessageContentFromJson(json);

  final String? name;

  final String? about;

  final String? picture;

  @JsonKey(name: 'display_name')
  final String? displayName;

  final String? website;

  final String? location;

  final String? category;

  @JsonKey(name: 'registered_at')
  final int? registeredAt;

  final String? banner;

  @JsonKey(name: 'who_can_message_you')
  final String? whoCanMessageYou;

  @JsonKey(name: 'who_can_invite_you_to_groups')
  final String? whoCanInviteYouToGroups;

  final Map<String, String>? wallets;

  @JsonKey(name: 'ion_content_nft_collections')
  final Map<String, IonContentNftCollection>? ionContentNftCollections;

  Map<String, dynamic> toJson() => _$UserDataEventMessageContentToJson(this);
}

enum WhoCanSetting {
  everyone,
  follows;

  static WhoCanSetting? fromString(String? value) => value == null
      ? null
      : WhoCanSetting.values.firstWhere(
          (element) => element.name == value,
          orElse: () => WhoCanSetting.everyone,
        );
}

@freezed
class IonContentNftCollection with _$IonContentNftCollection {
  const factory IonContentNftCollection({
    @JsonKey(name: 'created_by') required String createdBy,
    required String address,
  }) = _IonContentNftCollection;

  factory IonContentNftCollection.fromJson(Map<String, dynamic> json) =>
      _$IonContentNftCollectionFromJson(json);
}

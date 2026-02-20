// SPDX-License-Identifier: ice License 1.0
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/community_admin_tag.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/community_moderator_tag.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/community_openness_tag.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/community_visibility_tag.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/description_tag.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/name_tag.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/event_setting.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/services/uuid/generate_conversation_id.dart';

part 'community_definition_data.f.freezed.dart';

@Freezed(equal: false)
class CommunityDefinitionEntity
    with _$CommunityDefinitionEntity, IonConnectEntity, ImmutableEntity {
  const factory CommunityDefinitionEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required CommunityDefinitionData data,
    EventMessage? eventMessage,
  }) = _CommunityDefinitionEntity;

  const CommunityDefinitionEntity._();

  factory CommunityDefinitionEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw Exception('Incorrect event kind ${eventMessage.kind}, expected $kind');
    }

    return CommunityDefinitionEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: CommunityDefinitionData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }
  String get ownerPubkey => masterPubkey;

  // https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/ICIP-3000.md
  static const kind = 31750;
}

@Freezed(equal: false)
class CommunityDefinitionData with _$CommunityDefinitionData implements EventSerializable {
  const factory CommunityDefinitionData({
    required String uuid,
    required String id,
    required bool isPublic,
    required bool isOpen,
    required bool commentsEnabled,
    required RoleRequiredForPosting? roleRequiredForPosting,
    required List<String> moderators,
    required List<String> admins,
    required String name,
    required String? description,
    required MediaAttachment? avatar,
  }) = _CommunityDefinitionData;

  factory CommunityDefinitionData.fromData({
    required String name,
    required String? description,
    required MediaAttachment? avatar,
    required bool isPublic,
    required bool isOpen,
    required bool commentsEnabled,
    required RoleRequiredForPosting? roleRequiredForPosting,
    required List<String> moderators,
    required List<String> admins,
  }) {
    final uuid = generateConversationId(conversationType: ConversationType.community);
    return CommunityDefinitionData(
      uuid: uuid,
      id: uuid,
      name: name,
      description: description,
      avatar: avatar,
      isPublic: isPublic,
      isOpen: isOpen,
      commentsEnabled: commentsEnabled,
      roleRequiredForPosting: roleRequiredForPosting,
      moderators: moderators,
      admins: admins,
    );
  }

  const CommunityDefinitionData._();

  factory CommunityDefinitionData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    return CommunityDefinitionData(
      uuid: tags[ConversationIdentifier.tagName]!.map(ConversationIdentifier.fromTag).first.value,
      id: tags[ReplaceableEventIdentifier.tagName]!
          .map(ReplaceableEventIdentifier.fromTag)
          .first
          .value,
      name: tags[NameTag.tagName]!.map(NameTag.fromTag).first.value,
      description: tags[DescriptionTag.tagName]?.map(DescriptionTag.fromTag).first.value,
      avatar: tags[MediaAttachment.tagName]?.map(MediaAttachment.fromTag).first,
      isPublic: CommunityVisibilityTag.fromTags(eventMessage.tags).isPublic,
      isOpen: CommunityOpennessTag.fromTags(eventMessage.tags).isOpen,
      commentsEnabled: CommentsEnabledEventSetting.fromTags(eventMessage.tags).isEnabled,
      roleRequiredForPosting: RoleRequiredForPostingEventSetting.fromTags(eventMessage.tags).role,
      moderators: tags[CommunityModeratorTag.tagName]
              ?.map((tag) => CommunityModeratorTag.fromTag(tag).value)
              .toList() ??
          [],
      admins: tags[CommunityAdminTag.tagName]
              ?.map((tag) => CommunityAdminTag.fromTag(tag).value)
              .toList() ??
          [],
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
      kind: CommunityDefinitionEntity.kind,
      tags: [
        ...tags,
        ConversationIdentifier(value: uuid).toTag(),
        ReplaceableEventIdentifier(value: uuid).toTag(),
        NameTag(value: name).toTag(),
        if (description != null) DescriptionTag(value: description).toTag(),
        if (avatar != null) avatar!.toTag(),
        CommunityVisibilityTag(isPublic: isPublic).toTag(),
        CommunityOpennessTag(isOpen: isOpen).toTag(),
        CommentsEnabledEventSetting(isEnabled: commentsEnabled).toTag(),
        if (roleRequiredForPosting != null)
          RoleRequiredForPostingEventSetting(role: roleRequiredForPosting!).toTag(),
        if (moderators.isNotEmpty)
          ...moderators.map((moderator) => CommunityModeratorTag(value: moderator).toTag()),
        if (admins.isNotEmpty) ...admins.map((admin) => CommunityAdminTag(value: admin).toTag()),
      ],
      content: '',
    );
  }

  CommunityType get type {
    if (roleRequiredForPosting != null) {
      return CommunityType.channel;
    }

    return CommunityType.group;
  }

  //TODO: remove this when we have a real invitation link
  String get defaultInvitationLink => 'https://ice.io/iceofficialchannel';
}

enum CommunityType {
  channel,
  group,
}

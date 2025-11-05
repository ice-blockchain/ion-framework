// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/group_member_role.f.dart';
import 'package:ion/app/features/chat/model/group_subject.f.dart';
import 'package:ion/app/features/chat/model/message_type.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_encrypted_media_content.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_parent.dart';
import 'package:ion/app/features/ion_connect/model/entity_editing_ended_at.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_published_at.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/model/quoted_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/model/rich_text.f.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/services/ion_connect/ion_connect_protocol_identifier_type.dart';
import 'package:ion/app/utils/string.dart';

part 'encrypted_group_message_entity.f.freezed.dart';

@Freezed(equal: false)
class EncryptedGroupMessageEntity
    with IonConnectEntity, ReplaceableEntity, _$EncryptedGroupMessageEntity
    implements Comparable<EncryptedGroupMessageEntity> {
  const factory EncryptedGroupMessageEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required int createdAt,
    required EncryptedGroupMessageData data,
  }) = _EncryptedGroupMessageEntity;

  const EncryptedGroupMessageEntity._();

  factory EncryptedGroupMessageEntity.fromEventMessage(EventMessage eventMessage) {
    return EncryptedGroupMessageEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      createdAt: eventMessage.createdAt,
      masterPubkey: eventMessage.masterPubkey,
      data: EncryptedGroupMessageData.fromEventMessage(eventMessage),
    );
  }

  static const nameMaxLength = 100;

  @override
  String get signature => '';

  @override
  int compareTo(EncryptedGroupMessageEntity other) {
    return createdAt.compareTo(other.createdAt);
  }

  static const kind = 30014;
}

@freezed
class EncryptedGroupMessageData
    with
        EntityDataWithEncryptedMediaContent,
        EntityDataWithRelatedEvents<RelatedReplaceableEvent>,
        _$EncryptedGroupMessageData
    implements EventSerializable, ReplaceableEntityData {
  const factory EncryptedGroupMessageData({
    required String content,
    required String messageId,
    required String masterPubkey,
    required String conversationId,
    required Map<String, MediaAttachment> media,
    required EntityPublishedAt publishedAt,
    required EntityEditingEndedAt editingEndedAt,
    RichText? richText,
    String? groupImagePath,
    GroupSubject? groupSubject,
    List<RelatedReplaceableEvent>? relatedEvents,
    List<GroupMemberRole>? members,
    QuotedImmutableEvent? quotedEvent,
    String? quotedEventKind,
    String? paymentRequested,
    String? paymentSent,
  }) = _EncryptedGroupMessageData;

  factory EncryptedGroupMessageData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    if (tags[ReplaceableEventIdentifier.tagName] == null) {
      throw EncryptedMessageDecodeException(eventMessage.id);
    }

    return EncryptedGroupMessageData(
      content: eventMessage.content,
      masterPubkey: eventMessage.masterPubkey,
      media: EntityDataWithMediaContent.parseImeta(tags[MediaAttachment.tagName]),
      publishedAt: EntityPublishedAt.fromTag(tags[EntityPublishedAt.tagName]!.first),
      editingEndedAt: EntityEditingEndedAt.fromTag(tags[EntityEditingEndedAt.tagName]!.first),
      messageId: tags[ReplaceableEventIdentifier.tagName]!
          .map(ReplaceableEventIdentifier.fromTag)
          .first
          .value,
      members: tags[GroupMemberRole.tagName]?.map(GroupMemberRole.fromTag).toList(),
      relatedEvents:
          tags[RelatedReplaceableEvent.tagName]?.map(RelatedReplaceableEvent.fromTag).toList(),
      groupSubject: tags[GroupSubject.tagName]?.map(GroupSubject.fromTag).singleOrNull,
      quotedEvent:
          tags[QuotedImmutableEvent.tagName]?.map(QuotedImmutableEvent.fromTag).singleOrNull,
      quotedEventKind: tags[quotedEventKindTagName]?.first.elementAtOrNull(1),
      conversationId:
          tags[ConversationIdentifier.tagName]!.map(ConversationIdentifier.fromTag).first.value,
      paymentRequested: tags[paymentRequestedTagName]?.first.elementAtOrNull(1),
      paymentSent: tags[paymentSentTagName]?.first.elementAtOrNull(1),
    );
  }

  const EncryptedGroupMessageData._();

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
    int? publishedAtTime,
  }) {
    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt ?? DateTime.now().microsecondsSinceEpoch,
      kind: EncryptedGroupMessageEntity.kind,
      content: content,
      tags: [
        ...tags,
        MasterPubkeyTag(value: masterPubkey).toTag(),
        publishedAt.toTag(),
        editingEndedAt.toTag(),
        if (quotedEvent != null) quotedEvent!.toTag(),
        if (groupSubject != null) groupSubject!.toTag(),
        if (relatedEvents != null) ...relatedEvents!.map((event) => event.toTag()),
        if (members != null) ...members!.map((pubkey) => pubkey.toTag()),
        if (media.isNotEmpty) ...media.values.map((mediaAttachment) => mediaAttachment.toTag()),
        if (paymentRequested != null) [paymentRequestedTagName, paymentRequested!],
        if (paymentSent != null) [paymentSentTagName, paymentSent!],
        if (quotedEventKind != null) [quotedEventKindTagName, quotedEventKind.toString()],
        ReplaceableEventIdentifier(value: messageId).toTag(),
        ConversationIdentifier(value: conversationId).toTag(),
      ],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: EncryptedGroupMessageEntity.kind,
      dTag: messageId,
      masterPubkey: pubkey,
    );
  }

  static const textMessageLimit = 4096;
  static const videoDurationLimitInSeconds = 300;
  static const audioMessageDurationLimitInSeconds = 300;
  static const fileMessageSizeLimit = 25 * 1024 * 1024;

  static const paymentRequestedTagName = 'payment-requested';
  static const paymentSentTagName = 'payment-sent';
  static const quotedEventKindTagName = 'quoted-event-kind';
}

extension Pubkeys on EncryptedGroupMessageEntity {
  List<String> get allPubkeys => data.members?.map((member) => member.masterPubkey).toList() ?? []
    ..sort();
}

extension MessageTypes on EncryptedGroupMessageData {
  MessageType get messageType {
    if (primaryAudio != null) {
      return MessageType.audio;
    } else if (IonConnectProtocolIdentifierTypeValidator.isProfileIdentifier(content)) {
      return MessageType.profile;
    } else if (content.isEmoji) {
      return MessageType.emoji;
    } else if (visualMedias.isNotEmpty) {
      return MessageType.visualMedia;
    } else if (media.isNotEmpty) {
      return MessageType.document;
    }
    if (paymentRequested != null) {
      return MessageType.requestFunds;
    }
    if (paymentSent != null) {
      return MessageType.moneySent;
    } else if (IonConnectProtocolIdentifierTypeValidator.isEventIdentifier(content)) {
      if (EventReference.fromEncoded(content) case final ImmutableEventReference eventReference) {
        return switch (eventReference.kind) {
          FundsRequestEntity.kind => MessageType.requestFunds,
          WalletAssetEntity.kind => MessageType.moneySent,
          _ => MessageType.text,
        };
      }
    } else if (quotedEvent != null) {
      return MessageType.sharedPost;
    }

    return MessageType.text;
  }
}

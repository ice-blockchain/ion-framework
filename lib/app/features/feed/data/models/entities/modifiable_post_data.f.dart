// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/feed/polls/models/poll_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_parent.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_related_pubkeys.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_settings.dart';
import 'package:ion/app/features/ion_connect/model/entity_editing_ended_at.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_expiration.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_label.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_published_at.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/event_setting.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/model/quoted_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/model/rich_text.f.dart';
import 'package:ion/app/features/ion_connect/model/soft_deletable_entity.dart';
import 'package:ion/app/features/ion_connect/model/source_post_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/services/markdown/delta_markdown_converter.dart';

part 'modifiable_post_data.f.freezed.dart';

@Freezed(equal: false)
class ModifiablePostEntity
    with
        IonConnectEntity,
        CacheableEntity,
        ReplaceableEntity,
        SoftDeletableEntity<ModifiablePostData>,
        _$ModifiablePostEntity
    implements EntityEventSerializable, DbCacheableEntity {
  const factory ModifiablePostEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required ModifiablePostData data,
  }) = _ModifiablePostEntity;

  const ModifiablePostEntity._();

  /// https://github.com/ice-blockchain/subzero/blob/master/.ion-connect-protocol/ICIP-01.md
  factory ModifiablePostEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return ModifiablePostEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: ModifiablePostData.fromEventMessage(eventMessage),
    );
  }

  static const kind = 30175;
  static const storyKind = 57103;

  static const contentCharacterLimit = 4000;
  static const contentMediaLimit = 10;

  bool get isStory => data.expiration != null;

  @override
  FutureOr<EventMessage> toEntityEventMessage() => toEventMessage(data);
}

@freezed
class ModifiablePostData
    with
        SoftDeletableEntityData,
        EntityDataWithMediaContent,
        EntityDataWithSettings,
        EntityDataWithRelatedEvents,
        EntityDataWithRelatedPubkeys,
        _$ModifiablePostData
    implements EventSerializable, ReplaceableEntityData {
  const factory ModifiablePostData({
    required String textContent,
    required Map<String, MediaAttachment> media,
    required ReplaceableEventIdentifier replaceableEventId,
    required EntityPublishedAt publishedAt,
    EntityEditingEndedAt? editingEndedAt,
    EntityExpiration? expiration,
    QuotedEvent? quotedEvent,
    List<RelatedEvent>? relatedEvents,
    List<RelatedPubkey>? relatedPubkeys,
    List<RelatedHashtag>? relatedHashtags,
    List<EventSetting>? settings,
    String? communityId,
    RichText? richText,
    PollData? poll,
    SourcePostReference? sourcePostReference,
    EntityLabel? language,
  }) = _ModifiablePostData;

  factory ModifiablePostData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final quotedEventTag =
        tags[QuotedImmutableEvent.tagName] ?? tags[QuotedReplaceableEvent.tagName];

    // Check for richText first (prefer existing Delta)
    RichText? richText;
    if (tags[RichText.tagName] != null) {
      richText = RichText.fromTag(tags[RichText.tagName]!.first);
    } else {
      // No richText Delta, check for PMO tags to reconstruct Delta
      final pmoTags = tags['pmo'] ?? [];
      if (pmoTags.isNotEmpty) {
        // Map markdown (via PMO tags) to Delta
        final reconstructedDelta = DeltaMarkdownConverter.mapMarkdownToDelta(
          eventMessage.content,
          pmoTags,
        );
        richText = RichText(
          protocol: 'quill_delta',
          content: jsonEncode(reconstructedDelta.toJson()),
        );
      }
    }

    return ModifiablePostData(
      textContent: eventMessage.content,
      media: EntityDataWithMediaContent.parseImeta(tags[MediaAttachment.tagName]),
      replaceableEventId:
          ReplaceableEventIdentifier.fromTag(tags[ReplaceableEventIdentifier.tagName]!.first),
      publishedAt: EntityPublishedAt.fromTag(tags[EntityPublishedAt.tagName]!.first),
      editingEndedAt: tags[EntityEditingEndedAt.tagName] != null
          ? EntityEditingEndedAt.fromTag(tags[EntityEditingEndedAt.tagName]!.first)
          : null,
      expiration: tags[EntityExpiration.tagName] != null
          ? EntityExpiration.fromTag(tags[EntityExpiration.tagName]!.first)
          : null,
      quotedEvent: quotedEventTag != null ? QuotedEvent.fromTag(quotedEventTag.first) : null,
      relatedEvents: EntityDataWithRelatedEvents.fromTags(tags),
      relatedPubkeys: EntityDataWithRelatedPubkeys.fromTags(tags),
      relatedHashtags: tags[RelatedHashtag.tagName]?.map(RelatedHashtag.fromTag).toList(),
      settings: tags[EventSetting.settingTagName]?.map(EventSetting.fromTag).toList(),
      communityId:
          tags[ConversationIdentifier.tagName]?.map(ConversationIdentifier.fromTag).first.value,
      richText: richText,
      poll: tags['poll']?.firstOrNull != null ? PollData.fromTag(tags['poll']!.first) : null,
      sourcePostReference: SourcePostReference.fromTags(eventMessage.tags),
      language: EntityLabel.fromTags(tags, namespace: EntityLabelNamespace.language),
    );
  }

  const ModifiablePostData._();

  @override
  // Posts (kind 30175) use 100% text only - always return plain text, never Delta JSON
  String get content => textContent;

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) async {
    var contentToSign = content;
    final pmoTags = <List<String>>[];

    if (richText != null) {
      try {
        final deltaJson = jsonDecode(richText!.content) as List;
        final result = await DeltaMarkdownConverter.mapDeltaToPmo(deltaJson);
        contentToSign = result.text;
        pmoTags.addAll(result.tags.map((t) => t.toTag()));
      } catch (e) {
        // Fallback to existing content if conversion fails
      }
    }

    final allTags = [
      ...tags,
      ...pmoTags,
      replaceableEventId.toTag(),
      publishedAt.toTag(),
      if (editingEndedAt != null) editingEndedAt!.toTag(),
      if (expiration != null) expiration!.toTag(),
      if (quotedEvent != null) quotedEvent!.toTag(),
      if (relatedPubkeys != null) ...relatedPubkeys!.map((pubkey) => pubkey.toTag()),
      if (relatedHashtags != null) ...relatedHashtags!.map((hashtag) => hashtag.toTag()),
      if (relatedEvents != null) ...relatedEvents!.map((event) => event.toTag()),
      if (media.isNotEmpty) ...media.values.map((mediaAttachment) => mediaAttachment.toTag()),
      if (settings != null) ...settings!.map((setting) => setting.toTag()),
      if (communityId != null) ConversationIdentifier(value: communityId!).toTag(),
      // ModifiablePosts (kind 30175) use 100% text only with PMO tags, no rich_text tag
      if (poll != null) poll!.toTag(),
      if (sourcePostReference != null) sourcePostReference!.toTag(),
      if (language != null) ...language!.toTags(),
    ];

    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt,
      kind: ModifiablePostEntity.kind,
      content: contentToSign,
      tags: allTags,
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: ModifiablePostEntity.kind,
      masterPubkey: pubkey,
      dTag: replaceableEventId.value,
    );
  }

  @override
  String toString() {
    return 'ModifiablePostData(${richText?.content ?? content})';
  }
}

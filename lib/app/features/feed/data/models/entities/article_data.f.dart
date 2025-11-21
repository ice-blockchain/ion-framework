// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_related_pubkeys.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_settings.dart';
import 'package:ion/app/features/ion_connect/model/entity_editing_ended_at.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_label.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_published_at.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/event_setting.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/model/rich_text.f.dart';
import 'package:ion/app/features/ion_connect/model/soft_deletable_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/services/markdown/quill.dart';

part 'article_data.f.freezed.dart';

@Freezed(equal: false)
class ArticleEntity
    with
        IonConnectEntity,
        CacheableEntity,
        ReplaceableEntity,
        SoftDeletableEntity<ArticleData>,
        _$ArticleEntity
    implements EntityEventSerializable, DbCacheableEntity {
  const factory ArticleEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required ArticleData data,
  }) = _ArticleEntity;

  const ArticleEntity._();

  factory ArticleEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw Exception('Incorrect event kind ${eventMessage.kind}, expected $kind');
    }

    return ArticleEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: ArticleData.fromEventMessage(eventMessage),
    );
  }

  static const kind = 30023;

  @override
  FutureOr<EventMessage> toEntityEventMessage() => toEventMessage(data);
}

@freezed
class ArticleData
    with
        SoftDeletableEntityData,
        EntityDataWithMediaContent,
        EntityDataWithSettings,
        EntityDataWithRelatedPubkeys,
        _$ArticleData
    implements EventSerializable, ReplaceableEntityData {
  const factory ArticleData({
    required String textContent,
    required Map<String, MediaAttachment> media,
    required ReplaceableEventIdentifier replaceableEventId,
    required EntityPublishedAt publishedAt,
    RichText? richText,
    String? title,
    String? image,
    String? summary,
    List<RelatedHashtag>? relatedHashtags,
    List<RelatedPubkey>? relatedPubkeys,
    List<EventSetting>? settings,
    EntityLabel? colorLabel,
    EntityEditingEndedAt? editingEndedAt,
    EntityLabel? language,
  }) = _ArticleData;

  const ArticleData._();

  factory ArticleData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    final title = tags['title']?.firstOrNull?.elementAtOrNull(1);
    final image = tags['image']?.firstOrNull?.elementAtOrNull(1);
    final summary = tags['summary']?.firstOrNull?.elementAtOrNull(1);
    final mediaAttachments = _buildMedia(tags[MediaAttachment.tagName]);

    return ArticleData(
      textContent: eventMessage.content,
      media: mediaAttachments,
      title: title,
      image: image,
      summary: summary,
      publishedAt: EntityPublishedAt.fromTag(tags[EntityPublishedAt.tagName]!.first),
      replaceableEventId:
          ReplaceableEventIdentifier.fromTag(tags[ReplaceableEventIdentifier.tagName]!.first),
      relatedHashtags: tags[RelatedHashtag.tagName]?.map(RelatedHashtag.fromTag).toList(),
      relatedPubkeys: EntityDataWithRelatedPubkeys.fromTags(tags),
      settings: tags[EventSetting.settingTagName]?.map(EventSetting.fromTag).toList(),
      colorLabel: EntityLabel.fromTags(tags, namespace: EntityLabelNamespace.color),
      richText:
          tags[RichText.tagName] != null ? RichText.fromTag(tags[RichText.tagName]!.first) : null,
      editingEndedAt: tags[EntityEditingEndedAt.tagName] != null
          ? EntityEditingEndedAt.fromTag(tags[EntityEditingEndedAt.tagName]!.first)
          : null,
      language: EntityLabel.fromTags(tags, namespace: EntityLabelNamespace.language),
    );
  }

  factory ArticleData.fromData({
    required Map<String, MediaAttachment> media,
    String? title,
    String? image,
    String? summary,
    int? publishedAt,
    List<RelatedHashtag>? relatedHashtags,
    List<RelatedPubkey>? relatedPubkeys,
    List<EventSetting>? settings,
    String? imageColor,
    RichText? richText,
    EntityEditingEndedAt? editingEndedAt,
    EntityLabel? language,
    String textContent = '',
  }) {
    return ArticleData(
      textContent: textContent,
      media: media,
      title: title,
      image: image,
      summary: summary,
      publishedAt: EntityPublishedAt(value: publishedAt ?? DateTime.now().microsecondsSinceEpoch),
      replaceableEventId: ReplaceableEventIdentifier.generate(),
      relatedHashtags: relatedHashtags,
      relatedPubkeys: relatedPubkeys,
      settings: settings,
      colorLabel: imageColor != null
          ? EntityLabel(values: [imageColor], namespace: EntityLabelNamespace.color)
          : null,
      richText: richText,
      editingEndedAt: editingEndedAt,
      language: language,
    );
  }

  /// Converts rich text Delta to markdown content.
  ///
  /// Returns the markdown content, or falls back to textContent if conversion fails.
  String _convertRichTextToMarkdown(String textContent, RichText? richText) {
    if (richText != null) {
      try {
        final deltaJson = jsonDecode(richText.content) as List;
        final delta = Delta.fromJson(deltaJson);
        // Convert Delta to markdown
        return deltaToMarkdown(delta);
      } catch (e) {
        // Fallback to existing textContent if conversion fails
        return textContent;
      }
    }
    return textContent;
  }

  @override
  String get content => richText?.content ?? textContent;

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) async {
    final contentToSign = _convertRichTextToMarkdown(textContent, richText);

    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt,
      kind: ArticleEntity.kind,
      content: contentToSign,
      tags: [
        ...tags,
        replaceableEventId.toTag(),
        publishedAt.toTag(),
        if (title != null) ['title', title!],
        if (image != null) ['image', image!],
        if (summary != null) ['summary', summary!],
        if (media.isNotEmpty) ...media.values.map((mediaAttachment) => mediaAttachment.toTag()),
        if (colorLabel != null) ...colorLabel!.toTags(),
        if (settings != null) ...settings!.map((setting) => setting.toTag()),
        if (relatedHashtags != null) ...relatedHashtags!.map((hashtag) => hashtag.toTag()),
        if (relatedPubkeys != null) ...relatedPubkeys!.map((pubkey) => pubkey.toTag()),
        // Articles don't use rich_text tag - content is 100% markdown
        if (editingEndedAt != null) editingEndedAt!.toTag(),
        if (language != null) ...language!.toTags(),
      ],
    );
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: ArticleEntity.kind,
      masterPubkey: pubkey,
      dTag: replaceableEventId.value,
    );
  }

  List<String> get topics =>
      relatedHashtags
          ?.where((hashTag) => !RelatedHashtag.isTag(hashTag.value))
          .map((hashtag) => hashtag.value)
          .nonNulls
          .toList() ??
      [];

  static Map<String, MediaAttachment> _buildMedia(List<List<String>>? mediaTags) {
    if (mediaTags == null) return {};
    return {
      for (final tag in mediaTags)
        if (tag.length > 1) tag[1]: MediaAttachment.fromTag(tag),
    };
  }
}

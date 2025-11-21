// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_parent.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_settings.dart';
import 'package:ion/app/features/ion_connect/model/entity_expiration.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/event_setting.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/model/quoted_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/features/ion_connect/model/rich_text.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/services/markdown/delta_markdown_converter.dart';
import 'package:ion/app/services/markdown/quill.dart';

part 'post_data.f.freezed.dart';

@Freezed(equal: false)
class PostEntity
    with _$PostEntity, IonConnectEntity, ImmutableEntity, CacheableEntity
    implements EntityEventSerializable {
  const factory PostEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required PostData data,
  }) = _PostEntity;

  const PostEntity._();

  /// https://github.com/nostr-protocol/nips/blob/master/01.md
  factory PostEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return PostEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: PostData.fromEventMessage(eventMessage),
    );
  }

  static const kind = 1;

  bool get isStory => data.expiration != null;

  @override
  FutureOr<EventMessage> toEntityEventMessage() => toEventMessage(data);
}

@freezed
class PostData
    with _$PostData, EntityDataWithMediaContent, EntityDataWithSettings, EntityDataWithRelatedEvents
    implements EventSerializable {
  const factory PostData({
    required String content,
    required Map<String, MediaAttachment> media,
    RichText? richText,
    EntityExpiration? expiration,
    QuotedEvent? quotedEvent,
    List<RelatedEvent>? relatedEvents,
    List<RelatedPubkey>? relatedPubkeys,
    List<RelatedHashtag>? relatedHashtags,
    List<EventSetting>? settings,
  }) = _PostData;

  factory PostData.fromEventMessage(EventMessage eventMessage) {
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

    return PostData(
      content: eventMessage.content,
      media: EntityDataWithMediaContent.parseImeta(tags[MediaAttachment.tagName]),
      expiration: tags[EntityExpiration.tagName] != null
          ? EntityExpiration.fromTag(tags[EntityExpiration.tagName]!.first)
          : null,
      quotedEvent: quotedEventTag != null ? QuotedEvent.fromTag(quotedEventTag.first) : null,
      relatedEvents: EntityDataWithRelatedEvents.fromTags(tags),
      relatedPubkeys: tags[RelatedPubkey.tagName]?.map(RelatedPubkey.fromTag).toList(),
      relatedHashtags: tags[RelatedHashtag.tagName]?.map(RelatedHashtag.fromTag).toList(),
      settings: tags[EventSetting.settingTagName]?.map(EventSetting.fromTag).toList(),
      richText: richText,
    );
  }

  const PostData._();

  /// Converts content to plain text + PMO tags format.
  ///
  /// If [richText] exists, converts Delta → plain text + PMO tags.
  /// Otherwise, converts content → Delta → plain text + PMO tags for backward compatibility.
  Future<({String content, List<List<String>> pmoTags})> _convertToPmoFormat() async {
    Delta delta;

    if (richText != null) {
      // Use existing Delta from richText
      final deltaJson = jsonDecode(richText!.content) as List;
      delta = Delta.fromJson(deltaJson);
    } else {
      // Backward compatibility: Convert content to Delta
      delta = markdownToDelta(content);
    }

    try {
      final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());
      final plainText = richText != null
          ? result.text
          : result.text.trimRight(); // Trim trailing newline from markdownToDelta

      return (
        content: plainText,
        pmoTags: result.tags.map((t) => t.toTag()).toList(),
      );
    } catch (e) {
      // Fallback to existing content if conversion fails
      return (content: content, pmoTags: <List<String>>[]);
    }
  }

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) async {
    final conversion = await _convertToPmoFormat();

    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt,
      kind: PostEntity.kind,
      content: conversion.content,
      tags: [
        ...tags,
        ...conversion.pmoTags,
        if (expiration != null) expiration!.toTag(),
        if (quotedEvent != null) quotedEvent!.toTag(),
        if (relatedPubkeys != null) ...relatedPubkeys!.map((pubkey) => pubkey.toTag()),
        if (relatedHashtags != null) ...relatedHashtags!.map((hashtag) => hashtag.toTag()),
        if (relatedEvents != null) ...relatedEvents!.map((event) => event.toTag()),
        if (media.isNotEmpty) ...media.values.map((mediaAttachment) => mediaAttachment.toTag()),
        if (settings != null) ...settings!.map((setting) => setting.toTag()),
        // Posts (kind 1) use 100% text only with PMO tags, no rich_text tag
      ],
    );
  }

  @override
  String toString() {
    return 'PostData($content)';
  }
}

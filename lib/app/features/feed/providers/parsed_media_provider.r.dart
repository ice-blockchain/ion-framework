// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_related_pubkeys.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/markdown/quill.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'parsed_media_provider.r.g.dart';

@riverpod
Future<Delta> mentionsOverlay(
  Ref ref,
  EntityDataWithMediaContent data,
) async {
  keepAliveWhenAuthenticated(ref);

  final baseParsedMedia = parseMediaContent(data: data);
  if (data is! EntityDataWithRelatedPubkeys) {
    return baseParsedMedia.content;
  }

  final dataWithPubkeys = data as EntityDataWithRelatedPubkeys;
  final relatedPubkeys = dataWithPubkeys.relatedPubkeys;

  if (relatedPubkeys == null || relatedPubkeys.isEmpty) {
    return baseParsedMedia.content;
  }

  final usernameToPubkey = <String, String>{};

  await Future.wait(
    relatedPubkeys.map((relatedPubkey) async {
      final pubkey = relatedPubkey.value;
      try {
        final userMetadata = await ref.read(userMetadataProvider(pubkey, network: false).future);
        if (userMetadata != null && userMetadata.data.name.isNotEmpty) {
          usernameToPubkey[userMetadata.data.name] = pubkey;
        }
      } catch (_) {
        // Skip failed lookups
      }
    }),
  );

  if (usernameToPubkey.isEmpty) {
    return baseParsedMedia.content;
  }

  return restoreMentions(baseParsedMedia.content, usernameToPubkey);
}

({Delta content, List<MediaAttachment> media}) parseMediaContent({
  required EntityDataWithMediaContent data,
}) {
  final EntityDataWithMediaContent(:media, :richText) = data;

  // Get the actual text content for fallback
  // The content getter might return richText.content (JSON) if richText is set,
  // so we need to get the actual plain text content
  final textContent = switch (data) {
    final ModifiablePostData d => d.textContent,
    final PostData d => d.content,
    final ArticleData d => d.textContent,
    _ => data.content, // Fallback to content getter
  };

  Delta? delta;

  // For articles (kind 30023), content should be 100% markdown only.
  // Check if content is markdown and prioritize it over delta.
  final isMarkdownContent = isMarkdown(textContent);

  if (isMarkdownContent) {
    // Content is markdown - convert to delta (prioritize markdown for articles)
    delta = markdownToDelta(textContent);
    final mediaDelta = _parseMediaContentDelta(delta: delta, media: media);
    return (content: processDeltaMatches(mediaDelta.content), media: mediaDelta.media);
  }

  // If not markdown, try delta from richText if available
  if (richText != null) {
    try {
      final richTextDecoded = Delta.fromJson(jsonDecode(richText.content) as List<dynamic>);
      final richTextDelta = processDelta(richTextDecoded);
      final mediaDelta = _parseMediaContentDelta(delta: richTextDelta, media: media);
      return (content: processDeltaMatches(mediaDelta.content), media: mediaDelta.media);
    } catch (e) {
      // If parsing fails, fall through to plain text fallback
    }
  }

  // Fallback to plain text
  delta = plainTextToDelta(textContent);
  final mediaDeltaFallback = _parseMediaContentDelta(delta: delta, media: media);
  return (
    content: processDeltaMatches(mediaDeltaFallback.content),
    media: mediaDeltaFallback.media
  );
}

/// Parses the provided [delta] content to extract media links and separate them from non-media content.
///
/// Parameters:
/// - [delta]: The [Delta] object representing the content to be parsed.
/// - [media]: A map of all available media links.
///
/// Returns:
/// - [content]: A new [Delta] object with non-media operations.
/// - [media]: A list of [MediaAttachment] objects extracted from the content.
({Delta content, List<MediaAttachment> media}) _parseMediaContentDelta({
  required Delta delta,
  required Map<String, MediaAttachment> media,
}) {
  if (media.isEmpty) return (content: delta, media: []);

  final mediaFromContent = <MediaAttachment>[];
  final nonMediaOperations = <Operation>[];

  var afterMedia = false;
  for (final operation in delta.operations) {
    final attributes = operation.attributes;
    final value = operation.value;
    if (attributes != null &&
        attributes.containsKey(Attribute.link.key) &&
        media.containsKey(attributes[Attribute.link.key])) {
      afterMedia = true;
      mediaFromContent.add(media[attributes[Attribute.link.key]]!);
    } else if (value is String) {
      // [afterMedia] and [trimmedValue] are needed to handle the case with
      // processing Delta, that is built upon a plain text -
      // there we insert media links as plain text in the beginning of the content,
      // dividing those with a whitespace.
      // After the links are extracted, we need to remove the whitespaces as well.
      final trimmedValue =
          afterMedia && value.startsWith(' ') ? value.replaceFirst(' ', '') : value;
      afterMedia = false;

      if (trimmedValue.isNotEmpty) {
        // Preserve original attributes for non-media content
        nonMediaOperations.add(
          operation.attributes != null
              ? Operation.insert(trimmedValue, operation.attributes)
              : Operation.insert(trimmedValue),
        );
      }
    } else {
      // Preserve non-string operations (e.g. embeds)
      nonMediaOperations.add(operation);
    }
  }

  return (content: Delta.fromOperations(nonMediaOperations), media: mediaFromContent);
}

bool isMarkdown(String text) {
  // Common markdown patterns
  final patterns = [
    // Headers
    RegExp(r'^#{1,6}\s'),
    // Lists
    RegExp(r'^[-*+]\s'),
    RegExp(r'^\d+\.\s'),
    // Links
    RegExp(r'\[.*?\]\(.*?\)'),
    // Bold/Italic
    RegExp('[*_]{1,2}.*?[*_]{1,2}'),
    // Code blocks
    RegExp('`{1,3}.*?`{1,3}'),
    // Blockquotes
    RegExp(r'^\s*>\s'),
    // Tables
    RegExp(r'\|.*\|'),
    // Escaped characters
    RegExp(r'\\[\\`*_{}\[\]()#+\-.!]'),
  ];

  return patterns.any((pattern) => pattern.hasMatch(text));
}

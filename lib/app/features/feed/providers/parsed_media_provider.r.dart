// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
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
import 'package:ion/app/features/tokenized_communities/providers/bulk_token_market_info_prefetch_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/markdown/mention_label_utils.dart';
import 'package:ion/app/services/markdown/quill.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'parsed_media_provider.r.g.dart';

@riverpod
({Delta content, List<MediaAttachment> media}) parsedMediaWithMentions(
  Ref ref,
  EntityDataWithMediaContent data,
) {
  final baseParsedMedia = parseMediaContent(data: data);

  final mentions = ref.watch(mentionsOverlayProvider(data));

  final content = mentions.maybeWhen(
    data: (value) => value,
    orElse: () => baseParsedMedia.content,
  );

  return (content: content, media: baseParsedMedia.media);
}

@riverpod
String parsedMediaPlainText(
  Ref ref,
  EntityDataWithMediaContent data,
) {
  final parsed = ref.watch(parsedMediaWithMentionsProvider(data));
  return Document.fromDelta(parsed.content).toPlainText();
}

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

  // Extract labels from data and convert to restore format
  final mentionMarketCapLabel = switch (data) {
    final PostData d => d.mentionMarketCapLabel,
    final ModifiablePostData d => d.mentionMarketCapLabel,
    final ArticleData d => d.mentionMarketCapLabel,
    _ => null,
  };

  final cashtagMarketCapLabel = switch (data) {
    final PostData d => d.cashtagMarketCapLabel,
    final ModifiablePostData d => d.cashtagMarketCapLabel,
    final ArticleData d => d.cashtagMarketCapLabel,
    _ => null,
  };

  final pubkeyInstanceShowMarketCap = buildInstanceMapFromLabel(mentionMarketCapLabel);
  final cashtagInstanceExternalAddress =
      buildCashtagExternalAddressMapFromLabel(cashtagMarketCapLabel);

  // Bulk prefetch all cashtag token market info in a single API call
  final allCashtagExternalAddresses = cashtagInstanceExternalAddress.values
      .expand((instanceMap) => instanceMap.values)
      .toSet()
      .toList();
  if (allCashtagExternalAddresses.isNotEmpty) {
    unawaited(
      ref.read(bulkTokenMarketInfoPrefetchProvider(allCashtagExternalAddresses).future),
    );
  }

  // If there are no mentions to restore, still apply cashtag marketcap restoration.
  if (relatedPubkeys == null || relatedPubkeys.isEmpty) {
    if (cashtagInstanceExternalAddress.isEmpty) {
      return baseParsedMedia.content;
    }
    return restoreCashtagsMarketCap(baseParsedMedia.content, cashtagInstanceExternalAddress);
  }

  final usernameToPubkey = <String, String>{};

  await Future.wait(
    relatedPubkeys.map((relatedPubkey) async {
      final pubkey = relatedPubkey.value;

      try {
        final userMetadata = await ref.read(userMetadataProvider(pubkey).future);
        if (userMetadata != null && userMetadata.data.name.isNotEmpty) {
          usernameToPubkey[userMetadata.data.name] = pubkey;
        }
      } catch (_) {
        // Skip failed lookups
      }
    }),
  );

  final restoredMentionsDelta = usernameToPubkey.isEmpty
      ? baseParsedMedia.content
      : restoreMentions(
          baseParsedMedia.content,
          usernameToPubkey,
          pubkeyInstanceShowMarketCap: pubkeyInstanceShowMarketCap,
        );

  // Ensure matcher attributes exist, then apply per-instance cashtag marketcap restore last.
  final deltaWithMatches = processDeltaMatches(restoredMentionsDelta);
  return restoreCashtagsMarketCap(deltaWithMatches, cashtagInstanceExternalAddress);
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
    if (data is ArticleData) {
      delta = _sanitizeArticleTaggedFormattingMarkers(delta);
    }
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

Delta _sanitizeArticleTaggedFormattingMarkers(Delta delta) {
  final ops = delta.operations.toList();
  if (ops.length < 2) {
    return delta;
  }

  final mentionLinkPattern = RegExp(r'^(?:ion:|nostr:)?n(?:profile|pub)[a-z0-9]+$');

  bool isTagged(Operation op) {
    if (op.data is! String) {
      return false;
    }

    final attrs = op.attributes;
    if (attrs == null) {
      return false;
    }

    final text = op.data! as String;
    final trimmedText = text.trimLeft();
    final link = attrs['link'];

    final isMention = attrs['mention'] is String && trimmedText.startsWith('@');
    final isMentionLink =
        link is String && mentionLinkPattern.hasMatch(link) && trimmedText.startsWith('@');
    final isCashtag = trimmedText.startsWith(r'$') &&
        (attrs['cashtag'] is String || attrs['cashtagCoinId'] is String || link is String);

    return isMention || isMentionLink || isCashtag;
  }

  int markerLevel(String marker) {
    if (marker == '***') return 3;
    if (marker == '**') return 2;
    return 1;
  }

  for (var i = 0; i < ops.length; i++) {
    final op = ops[i];
    if (op.data is! String || !isTagged(op)) {
      continue;
    }

    var taggedText = op.data! as String;
    final taggedAttrs = Map<String, dynamic>.from(op.attributes ?? const {});

    final inlineUnderline =
        RegExp(r'^\s*<u>\s*(.*?)\s*</u>\s*$', dotAll: true).firstMatch(taggedText);
    if (inlineUnderline != null) {
      final inner = inlineUnderline.group(1)!;
      if (inner.isNotEmpty) {
        taggedText = inner;
        taggedAttrs['underline'] = true;
        ops[i] = Operation.insert(taggedText, taggedAttrs);
      }
    }

    final inlineWrapper =
        RegExp(r'^\s*(\*\*\*|\*\*|\*)\s*(.*?)\s*\1\s*$', dotAll: true).firstMatch(taggedText);
    if (inlineWrapper != null) {
      final marker = inlineWrapper.group(1)!;
      final inner = inlineWrapper.group(2)!;
      if (inner.isNotEmpty) {
        taggedText = inner;
        final level = markerLevel(marker);
        if (level >= 2) taggedAttrs['bold'] = true;
        if (level == 1 || level == 3) taggedAttrs['italic'] = true;
        ops[i] = Operation.insert(taggedText, taggedAttrs);
      }
    }

    if (i == 0 || i == ops.length - 1) {
      continue;
    }

    final prevOp = ops[i - 1];
    final nextOp = ops[i + 1];
    if (prevOp.data is! String || nextOp.data is! String) {
      continue;
    }

    final prevText = prevOp.data! as String;
    final nextText = nextOp.data! as String;
    final prevMatch = RegExp(r'(\*\*\*|\*\*|\*)\s*$').firstMatch(prevText);
    final nextMatch = RegExp(r'^\s*(\*\*\*|\*\*|\*)').firstMatch(nextText);
    final prevUnderlineMatch = RegExp(r'<u>\s*$').firstMatch(prevText);
    final nextUnderlineMatch = RegExp(r'^\s*</u>').firstMatch(nextText);

    if (prevMatch != null && nextMatch != null) {
      final marker = prevMatch.group(1)!;
      if (marker == nextMatch.group(1)) {
        final prevWithoutMarker = prevText.substring(0, prevMatch.start);
        final nextWithoutMarker = nextText.substring(nextMatch.end);
        final level = markerLevel(marker);

        final mergedAttrs = Map<String, dynamic>.from(ops[i].attributes ?? const {});
        if (level >= 2) mergedAttrs['bold'] = true;
        if (level == 1 || level == 3) mergedAttrs['italic'] = true;

        ops[i - 1] = Operation.insert(prevWithoutMarker, prevOp.attributes);
        ops[i] = Operation.insert((ops[i].data! as String).trim(), mergedAttrs);
        ops[i + 1] = Operation.insert(nextWithoutMarker, nextOp.attributes);
      }
    }

    if (prevUnderlineMatch != null && nextUnderlineMatch != null) {
      final prevWithoutTag = prevText.substring(0, prevUnderlineMatch.start);
      final nextWithoutTag = nextText.substring(nextUnderlineMatch.end);
      final mergedAttrs = Map<String, dynamic>.from(ops[i].attributes ?? const {});
      mergedAttrs['underline'] = true;

      ops[i - 1] = Operation.insert(prevWithoutTag, prevOp.attributes);
      ops[i] = Operation.insert((ops[i].data! as String).trim(), mergedAttrs);
      ops[i + 1] = Operation.insert(nextWithoutTag, nextOp.attributes);
    }
  }

  final sanitized = Delta();
  for (final op in ops) {
    if (op.data is String && (op.data! as String).isEmpty) {
      continue;
    }
    sanitized.insert(op.data, op.attributes);
  }

  return sanitized;
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

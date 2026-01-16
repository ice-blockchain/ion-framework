// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_single_image_block/text_editor_single_image_block.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/services/text_parser/model/text_matcher.dart';
import 'package:ion/app/services/text_parser/text_parser.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

final _mdDocument = md.Document(
  encodeHtml: false,
  extensionSet: md.ExtensionSet.gitHubFlavored,
);

final _mdToDelta = MarkdownToDelta(
  markdownDocument: _mdDocument,
  softLineBreak: true,
  customElementToEmbeddable: {
    'img': (attrs) {
      final imageUrl = attrs['src'] ?? '';
      return TextEditorSingleImageEmbed(imageUrl);
    },
  },
);

Delta plainTextToDelta(String text) {
  final matches = TextParser.allMatchers().parse(text.trim());
  final operations = <Operation>[];

  for (final match in matches) {
    operations.add(
      switch (match.matcher) {
        UrlMatcher() => Operation.insert(match.text, {Attribute.link.key: match.text}),
        HashtagMatcher() =>
          Operation.insert(match.text, {HashtagAttribute.attributeKey: match.text}),
        CashtagMatcher() =>
          Operation.insert(match.text, {CashtagAttribute.attributeKey: match.text}),
        _ => Operation.insert(match.text),
      },
    );
  }

  operations.add(Operation.insert('\n'));

  return Delta.fromOperations(operations);
}

final deltaToMd = DeltaToMarkdown(
  customEmbedHandlers: {
    'text-editor-single-image': (embed, out) {
      final imageUrl = embed.value.data;
      out.write('![image]($imageUrl)');
    },
    'text-editor-separator': (embed, out) {
      out.write('\n---\n');
    },
    'text-editor-code': (embed, out) {
      final content = embed.value.data;
      out.write('\n```\n$content\n```\n');
    },
  },
  visitLineHandleNewLine: (style, out) {
    out.write('\n');
  },
);

String deltaToMarkdown(Delta delta) {
  final processedDelta = Delta();

  for (final op in delta.operations) {
    if (op.key == 'insert') {
      if (op.data is Map) {
        processedDelta.insert(op.data);
      } else if (op.attributes?.containsKey('text-editor-single-image') ?? false) {
        processedDelta.insert({
          'text-editor-single-image': op.attributes!['text-editor-single-image'],
        });
      } else {
        final data = op.data;
        final attributes = op.attributes;

        // Handle mentions: convert mention attribute to link attribute
        if (data is String && (attributes?.containsKey(MentionAttribute.attributeKey) ?? false)) {
          final bech32Value = attributes![MentionAttribute.attributeKey] as String;

          // Create attributes with link instead of mention
          final linkAttributes = Map<String, dynamic>.from(attributes)
            ..remove(MentionAttribute.attributeKey)
            ..remove(MentionAttribute.showMarketCapKey)
            ..[Attribute.link.key] = bech32Value;

          processedDelta.insert(data, linkAttributes);
        }
        // Handle underline: markdown doesn't support underline natively,
        // so we need to wrap it in HTML <u> tags
        else if (data is String && (attributes?.containsKey('underline') ?? false)) {
          // Check if there are other attributes (bold, italic) that need to be handled
          final hasBold = attributes?.containsKey('bold') ?? false;
          final hasItalic = attributes?.containsKey('italic') ?? false;

          // Build the markdown with underline as HTML <u> tags
          var text = data;

          // Apply bold and italic first (markdown syntax)
          if (hasBold && hasItalic) {
            text = '***$text***';
          } else if (hasBold) {
            text = '**$text**';
          } else if (hasItalic) {
            text = '*$text*';
          }

          // Wrap in <u> tags for underline
          text = '<u>$text</u>';

          // Insert as plain text - the markdown converter should preserve HTML
          processedDelta.insert(text);
        } else {
          processedDelta.insert(op.data, op.attributes);
        }
      }
    }
  }

  final markdown = deltaToMd.convert(processedDelta);

  // Post-process to ensure <u> tags are preserved (not escaped)
  // The markdown converter might escape HTML, so we unescape <u> tags
  final processedMarkdown = markdown.replaceAll(r'\<u\>', '<u>').replaceAll(r'\</u\>', '</u>');

  // Add two spaces before single newlines to create hard breaks in markdown
  // This ensures line breaks are preserved when converting back to Delta
  // We don't modify newlines that already have two spaces, double newlines (paragraphs),
  // or newlines inside code blocks (code blocks already preserve newlines)
  return processedMarkdown.replaceAllMapped(
    RegExp(r'(?<!  )\n(?!\n)(?!```)'),
    (match) {
      // Check if this newline is inside a code block
      final beforeMatch = processedMarkdown.substring(0, match.start);
      final codeBlockOpenCount = beforeMatch.split('```').length - 1;
      // If we have an odd number of ```, we're inside a code block
      if (codeBlockOpenCount.isOdd) {
        return '\n'; // Don't add spaces inside code blocks
      }
      return '  \n';
    },
  );
}

Delta markdownToDelta(String markdown) {
  // Pre-process markdown to extract and handle mention links with bech32 encoding
  // Pattern: [@username](ion:nprofile...) or [@username](nostr:npub...)
  final mentionPattern = RegExp(r'\[@([^\]]+)\]\(((?:ion:|nostr:)?n(?:profile|pub)[a-z0-9]+)\)');
  final mentions = <({int start, int end, String username, String bech32})>[];

  // Find all mention matches
  for (final match in mentionPattern.allMatches(markdown)) {
    mentions.add(
      (
        start: match.start,
        end: match.end,
        username: match.group(1)!,
        bech32: match.group(2)!,
      ),
    );
  }

  // Replace mentions with plain text temporarily for markdown parsing
  var processedMarkdown = markdown;
  var offset = 0;
  for (final mention in mentions) {
    final adjustedStart = mention.start + offset;
    final adjustedEnd = mention.end + offset;
    final placeholder = '@${mention.username}';
    processedMarkdown = processedMarkdown.substring(0, adjustedStart) +
        placeholder +
        processedMarkdown.substring(adjustedEnd);
    offset += placeholder.length - (mention.end - mention.start);
  }

  final delta = _mdToDelta.convert(processedMarkdown);
  final processedDelta = Delta();

  // Build a map of @username -> bech32 for quick lookup
  final usernameToBech32 = <String, String>{};
  for (final mention in mentions) {
    usernameToBech32['@${mention.username}'] = mention.bech32;
  }

  for (final op in delta.operations) {
    if (op.key == 'insert' && op.data is Map) {
      final data = op.data! as Map;
      if (data.containsKey('image')) {
        final imageUrl = data['image'] as String;
        processedDelta.insert({
          'text-editor-single-image': imageUrl,
        });
      } else if (data.containsKey('divider')) {
        processedDelta.insert({
          'text-editor-separator': '---',
        });
      } else {
        processedDelta.insert(op.data, _normalizeAttributes(op.attributes));
      }
    } else if (op.key == 'insert' && op.data is String) {
      // Check for HTML <u> tags and convert them to underline attributes
      final text = op.data! as String;
      var attrs = _normalizeAttributes(op.attributes);

      // Check if this text matches a mention we extracted
      if (usernameToBech32.containsKey(text)) {
        final bech32 = usernameToBech32[text]!;
        // Insert the username with mention attribute
        attrs = {
          ...?attrs,
          MentionAttribute.attributeKey: bech32,
        };
        processedDelta.insert(text, attrs);
        continue;
      }

      // Check if this is a mention link with bech32 encoding (fallback for other formats)
      // Markdown parser converts [@username](bech32) to: insert "@username" with link attribute = "bech32"
      if (attrs != null && attrs.containsKey('link')) {
        final linkValue = attrs['link'] as String?;

        // Check if the link is a bech32 encoded mention (ion: or nostr: prefix)
        if (linkValue != null && _isBech32Mention(linkValue)) {
          // Convert link attribute to mention attribute
          attrs = {
            ...attrs,
            MentionAttribute.attributeKey: linkValue,
          }..remove('link');
          processedDelta.insert(text, attrs);
          continue;
        }
      }

      // Pattern to match <u>...</u> tags, including nested markdown formatting
      final underlinePattern = RegExp('<u>(.*?)</u>', dotAll: true);

      if (underlinePattern.hasMatch(text)) {
        // Process text with <u> tags
        var lastEnd = 0;
        final matches = underlinePattern.allMatches(text);

        for (final match in matches) {
          // Add text before the tag
          if (match.start > lastEnd) {
            final beforeText = text.substring(lastEnd, match.start);
            if (beforeText.isNotEmpty) {
              processedDelta.insert(beforeText, attrs);
            }
          }

          // Process the content inside <u> tags
          final underlinedContent = match.group(1) ?? '';

          // Check for markdown formatting inside the <u> tags
          final hasBold = underlinedContent.contains('**');
          final hasItalic = underlinedContent.contains('*') && !hasBold;
          final hasBoldItalic = underlinedContent.contains('***');

          // Extract plain text by removing markdown formatting
          final plainText =
              underlinedContent.replaceAll('***', '').replaceAll('**', '').replaceAll('*', '');

          // Build attributes
          final underlineAttrs = <String, dynamic>{
            'underline': true,
            if (hasBoldItalic || hasBold) 'bold': true,
            if (hasBoldItalic || hasItalic) 'italic': true,
            ...?attrs,
          };

          processedDelta.insert(plainText, underlineAttrs);
          lastEnd = match.end;
        }

        // Add remaining text after last tag
        if (lastEnd < text.length) {
          final afterText = text.substring(lastEnd);
          if (afterText.isNotEmpty) {
            processedDelta.insert(afterText, attrs);
          }
        }
      } else {
        // No underline tags, insert normally with normalized attributes
        processedDelta.insert(op.data, attrs);
      }
    } else {
      processedDelta.insert(op.data, _normalizeAttributes(op.attributes));
    }
  }

  return withFullLinks(processedDelta);
}

/// Normalizes attributes to ensure they use string keys that QuillEditor expects.
/// The markdown_quill package may return attributes in different formats, so we
/// normalize them to ensure consistent handling.
Map<String, dynamic>? _normalizeAttributes(Map<String, dynamic>? attrs) {
  if (attrs == null || attrs.isEmpty) return attrs;

  // Map of alternative keys to normalized keys
  // Handles both string keys ('bold', 'strong', 'italic', 'em') and Attribute object keys
  final keyNormalizations = <String, String>{
    'bold': 'bold',
    'strong': 'bold',
    Attribute.bold.key: 'bold',
    'italic': 'italic',
    'em': 'italic',
    Attribute.italic.key: 'italic',
  };

  final normalized = <String, dynamic>{};

  for (final entry in attrs.entries) {
    final normalizedKey = keyNormalizations[entry.key];

    if (normalizedKey != null) {
      // Normalize bold/italic keys and ensure they're set to true
      normalized[normalizedKey] = true;
    } else {
      // Preserve other attributes as-is
      normalized[entry.key] = entry.value;
    }
  }

  return normalized.isEmpty ? null : normalized;
}

/// Checks if a string is a bech32 encoded mention.
bool _isBech32Mention(String value) {
  final bech32Pattern = RegExp(r'^(?:ion:|nostr:)?n(?:profile|pub)[a-z0-9]+$');
  return bech32Pattern.hasMatch(value);
}

void _processMatches(Operation op, Delta processedDelta) {
  if (op.data is Map) {
    processedDelta.insert(op.data, op.attributes);
    return;
  }

  final textParser = TextParser.tagsMatchers();
  final text = op.data.toString();
  final matches = textParser.parse(text);

  if (matches.isEmpty) {
    processedDelta.insert(op.data, op.attributes);
  } else {
    for (final match in matches) {
      processedDelta.insert(
        match.text,
        {
          ...?op.attributes,
          ...switch (match.matcher) {
            HashtagMatcher() => {HashtagAttribute.attributeKey: match.text},
            CashtagMatcher() => {CashtagAttribute.attributeKey: match.text},
            _ => {},
          },
        },
      );
    }
  }
}

Delta processDelta(Delta delta) {
  final newDelta = Delta();

  for (final op in delta.operations) {
    if (op.data is String && (op.attributes?.containsKey('text-editor-single-image') ?? false)) {
      final imageUrl = op.attributes!['text-editor-single-image'] as String;
      newDelta.insert({'text-editor-single-image': imageUrl});
    } else {
      newDelta.insert(op.data, op.attributes);
    }
  }

  return withFullLinks(newDelta);
}

Delta parseAndConvertDelta(String? deltaContent, String fallbackMarkdown) {
  Delta? delta;

  try {
    if (deltaContent != null) {
      delta = Delta.fromJson(jsonDecode(deltaContent) as List<dynamic>);
      delta = processDelta(delta);
      delta = processDeltaMatches(delta);
    }
  } catch (e) {
    delta = null;
  }

  // Fallback to markdown if delta parsing failed
  if (delta != null) {
    return delta;
  }

  // Ensure hashtags are processed when falling back to markdown
  final markdownDelta = markdownToDelta(fallbackMarkdown);
  return processDeltaMatches(markdownDelta);
}

Delta processDeltaMatches(Delta delta) {
  final newDelta = Delta();
  for (final op in delta.operations) {
    _processMatches(op, newDelta);
  }
  return newDelta;
}

/// Restores MentionAttribute for @mentions in the Delta by matching usernames to pubkeys.
///
/// Parameters:
/// - [delta]: The Delta to process
/// - [usernameToPubkey]: Map of username (without @) to pubkey
/// - [pubkeyShowMarketCap]: Map of pubkey to showMarketCap flag (optional)
///
/// Returns: Delta with MentionAttribute restored for matching mentions
Delta restoreMentions(
  Delta delta,
  Map<String, String> usernameToPubkey, {
  Map<String, Set<int>>? pubkeyInstanceShowMarketCap,
}) {
  if (usernameToPubkey.isEmpty) {
    return delta;
  }

  final textParser = TextParser.tagsMatchers();
  final newDelta = Delta();
  final mentionInstanceTracker = <String, int>{}; // Track mention instance index per pubkey

  for (final op in delta.operations) {
    if (op.data is Map) {
      newDelta.insert(op.data, op.attributes);
      continue;
    }

    if (op.data is! String) {
      newDelta.insert(op.data, op.attributes);
      continue;
    }

    final text = op.data! as String;
    final segments = textParser.parse(text);

    if (segments.isEmpty) {
      newDelta.insert(op.data, op.attributes);
      continue;
    }

    for (final segment in segments) {
      if (segment.matcher is MentionMatcher) {
        final mentionText = segment.text;
        // Remove @ prefix to get username
        final username = mentionText.startsWith('@') ? mentionText.substring(1) : mentionText;
        final pubkey = usernameToPubkey[username];

        if (pubkey != null) {
          // Get current instance index for this pubkey
          final currentInstance = mentionInstanceTracker[pubkey] ?? 0;
          mentionInstanceTracker[pubkey] =
              currentInstance + 1; // Increment per-pubkey (matches save logic for symmetry)

          // Create MentionAttribute with encoded reference
          final userMetadataRef = ReplaceableEventReference(
            masterPubkey: pubkey,
            kind: UserMetadataEntity.kind,
          );
          final encodedRef = userMetadataRef.encode();

          // Check if THIS specific instance should show market cap (per-instance control)
          final instanceNumbers = pubkeyInstanceShowMarketCap?[pubkey];
          final showMarketCap = instanceNumbers?.contains(currentInstance) ?? false;

          final mentionAttrs = {
            ...?op.attributes,
            MentionAttribute.attributeKey: encodedRef,
            if (showMarketCap) MentionAttribute.showMarketCapKey: true,
          };

          newDelta.insert(mentionText, mentionAttrs);
        } else {
          // No matching pubkey found, insert as plain text
          newDelta.insert(mentionText, op.attributes);
        }
      } else {
        // Plain text or other matcher (hashtag, cashtag)
        // Preserve existing attributes and add any matcher-specific attributes
        final attrs = {
          ...?op.attributes,
          ...switch (segment.matcher) {
            HashtagMatcher() => {HashtagAttribute.attributeKey: segment.text},
            CashtagMatcher() => {CashtagAttribute.attributeKey: segment.text},
            _ => <String, dynamic>{},
          },
        };
        newDelta.insert(segment.text, attrs);
      }
    }
  }

  return newDelta;
}

Delta withFullLinks(Delta delta) {
  final out = Delta();
  for (final op in delta.toList()) {
    final href = op.attributes?[Attribute.link.key];
    if (href != null && op.value is String && op.value == ' ') {
      out.push(Operation.insert(href, {Attribute.link.key: href}));
    } else {
      out.push(op);
    }
  }
  return out;
}
